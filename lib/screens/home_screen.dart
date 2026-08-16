import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory_item.dart';
import '../database/database_helper.dart';
import '../services/pdf_service.dart';
import 'add_edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;
  List<InventoryItem> _items = [];
  int? _selectedId; // معرف العنصر المحدد حالياً (لإظهار أزرار تعديل/حذف)
  bool _loading = true;

  static const primaryColor = Color(0xFF1E5AA8);
  static const dangerColor = Color(0xFFD9534F);
  static const successColor = Color(0xFF2E9E5B);

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await _db.getAllItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  InventoryItem? get _selectedItem {
    if (_selectedId == null) return null;
    try {
      return _items.firstWhere((it) => it.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAddScreen() async {
    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
    );
    if (result != null) {
      await _db.insertItem(result);
      await _loadItems();
      _showSnack('تمت إضافة المادة بنجاح', successColor);
    }
  }

  Future<void> _openEditScreen() async {
    final item = _selectedItem;
    if (item == null) return;
    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(builder: (_) => AddEditItemScreen(existingItem: item)),
    );
    if (result != null) {
      await _db.updateItem(result);
      await _loadItems();
      _showSnack('تم حفظ التعديلات', successColor);
    }
  }

  Future<void> _deleteSelected() async {
    final item = _selectedItem;
    if (item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: dangerColor),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _db.deleteItem(item.id!);
      setState(() => _selectedId = null);
      await _loadItems();
      _showSnack('تم حذف المادة', dangerColor);
    }
  }

  Future<void> _handlePrint() async {
    if (_items.isEmpty) {
      _showSnack('لا توجد بيانات لطباعتها', Colors.grey);
      return;
    }
    // يعرض خيارات: طباعة مباشرة، حفظ PDF، أو مشاركة (بما فيها واتساب)
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.print_outlined, color: primaryColor),
                title: const Text('طباعة / حفظ PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  PdfService.printPdf(_items);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFF25D366)),
                title: const Text('مشاركة عبر واتساب أو تطبيق آخر'),
                onTap: () {
                  Navigator.pop(ctx);
                  PdfService.sharePdf(_items);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedId != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('إدارة المخزن',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'طباعة / مشاركة',
              icon: const Icon(Icons.print_outlined),
              onPressed: _handlePrint,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? _buildEmptyState()
                : _buildTable(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddScreen,
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add),
          label: Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        ),
        bottomNavigationBar: hasSelection ? _buildActionBar() : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('لا توجد مواد في المخزن بعد',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('اضغط + لإضافة أول مادة',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  /// شريط سفلي يظهر فقط عند تحديد عنصر - يحوي زري تعديل وحذف
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openEditScreen,
                icon: const Icon(Icons.edit_outlined),
                label: Text('تعديل', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(primaryColor.withOpacity(0.08)),
            columnSpacing: 24,
            columns: [
              _col('التسلسل'),
              _col('اسم المادة'),
              _col('المستلمة'),
              _col('المصروفة'),
              _col('المسلمة'),
              _col('الباقي بالمخزن'),
            ],
            rows: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = item.id == _selectedId;
              final lowStock = item.remaining <= 0;

              return DataRow(
                selected: selected,
                color: WidgetStateProperty.resolveWith((states) {
                  if (selected) return primaryColor.withOpacity(0.12);
                  return index.isEven ? Colors.white : const Color(0xFFF9FAFC);
                }),
                onSelectChanged: (_) {
                  setState(() {
                    _selectedId = selected ? null : item.id;
                  });
                },
                cells: [
                  DataCell(Text('${index + 1}', style: GoogleFonts.cairo())),
                  DataCell(Text(item.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600))),
                  DataCell(Text(_fmt(item.received), style: GoogleFonts.cairo())),
                  DataCell(Text(_fmt(item.issued), style: GoogleFonts.cairo())),
                  DataCell(Text(_fmt(item.delivered), style: GoogleFonts.cairo())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lowStock ? dangerColor.withOpacity(0.12) : successColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _fmt(item.remaining),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: lowStock ? dangerColor : successColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  DataColumn _col(String label) => DataColumn(
        label: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      );

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
