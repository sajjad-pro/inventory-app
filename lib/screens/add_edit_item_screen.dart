import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory_item.dart';

/// شاشة موحّدة للإضافة والتعديل معاً
/// إن تم تمرير [existingItem] تعمل الشاشة في وضع "تعديل"، وإلا "إضافة"
class AddEditItemScreen extends StatefulWidget {
  final InventoryItem? existingItem;

  const AddEditItemScreen({super.key, this.existingItem});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _receivedCtrl;
  late final TextEditingController _issuedCtrl;
  late final TextEditingController _deliveredCtrl;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _receivedCtrl =
        TextEditingController(text: item != null ? _fmt(item.received) : '');
    _issuedCtrl =
        TextEditingController(text: item != null ? _fmt(item.issued) : '');
    _deliveredCtrl =
        TextEditingController(text: item != null ? _fmt(item.delivered) : '');
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _receivedCtrl.dispose();
    _issuedCtrl.dispose();
    _deliveredCtrl.dispose();
    super.dispose();
  }

  /// تحقق عام: رقم غير سالب
  String? _validateNumber(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال $label';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$label يجب أن يكون رقماً صحيحاً';
    }
    if (parsed < 0) {
      return '$label لا يمكن أن يكون سالباً';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final received = double.parse(_receivedCtrl.text.trim());
    final issued = double.parse(_issuedCtrl.text.trim());
    final delivered = double.parse(_deliveredCtrl.text.trim());

    // تحقق منطقي إضافي: لا يمكن صرف/تسليم أكثر من المستلم
    if (issued + delivered > received) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'مجموع الكمية المصروفة والمسلمة أكبر من الكمية المستلمة!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = InventoryItem(
      id: widget.existingItem?.id,
      name: _nameCtrl.text.trim(),
      received: received,
      issued: issued,
      delivered: delivered,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            isEditing ? 'تعديل مادة' : 'إضافة مادة جديدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF1E5AA8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildField(
                controller: _nameCtrl,
                label: 'اسم المادة',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.text,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'الرجاء إدخال اسم المادة'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _receivedCtrl,
                label: 'الكمية المستلمة',
                icon: Icons.download_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validateNumber(v, label: 'الكمية المستلمة'),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _issuedCtrl,
                label: 'الكمية المصروفة',
                icon: Icons.upload_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validateNumber(v, label: 'الكمية المصروفة'),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _deliveredCtrl,
                label: 'الكمية المسلمة',
                icon: Icons.local_shipping_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validateNumber(v, label: 'الكمية المسلمة'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isEditing ? 'حفظ التعديلات' : 'إضافة المادة',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      validator: validator,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: const Color(0xFF1E5AA8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E5AA8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderS
