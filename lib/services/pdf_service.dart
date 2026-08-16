import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';

/// خدمة مسؤولة عن توليد تقرير PDF لبيانات المخزن ومشاركته
///
/// ملاحظة مهمة: مكتبة pdf لا تدعم رسم الحروف العربية افتراضياً،
/// لذلك نقوم بتحميل خط عربي (مثل Cairo أو NotoNaskhArabic) من مجلد assets.
/// يجب إضافة ملف الخط في assets/fonts/Cairo-Regular.ttf وتسجيله في pubspec.yaml:
///   flutter:
///     assets:
///       - assets/fonts/Cairo-Regular.ttf
class PdfService {
  /// يولّد ملف PDF يحتوي جدول المخزن كاملاً ويعيد مسار الملف
  static Future<File> generateInventoryPdf(List<InventoryItem> items) async {
    // تحميل الخط العربي - ضروري لظهور النصوص العربية بشكل صحيح
    final fontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final arabicFont = pw.Font.ttf(fontData);
    final ttfTheme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);

    final pdf = pw.Document(theme: ttfTheme);

    final headers = [
      'التسلسل',
      'اسم المادة',
      'المستلمة',
      'المصروفة',
      'المسلمة',
      'الباقي',
    ];

    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        '${i + 1}',
        it.name,
        it.received.toStringAsFixed(0),
        it.issued.toStringAsFixed(0),
        it.delivered.toStringAsFixed(0),
        it.remaining.toStringAsFixed(0),
      ]);
    }

    final dateStr = DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('تقرير حالة المخزن',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('تاريخ التقرير: $dateStr',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            rowDecoration: const pw.BoxDecoration(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('إجمالي عدد الأصناف: ${items.length}',
              style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// يعرض معاينة الطباعة الأصلية للنظام (يدعم الطباعة المباشرة)
  static Future<void> printPdf(List<InventoryItem> items) async {
    final file = await generateInventoryPdf(items);
    await Printing.layoutPdf(onLayout: (format) => file.readAsBytes());
  }

  /// يشارك ملف الـ PDF عبر أي تطبيق مثبت (بما فيه واتساب)
  static Future<void> sharePdf(List<InventoryItem> items) async {
    final file = await generateInventoryPdf(items);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'تقرير حالة المخزن',
    );
    // ملاحظة: shareXFiles يفتح قائمة المشاركة النظامية،
    // والمستخدم يختار "واتساب" منها مباشرة إن كان مثبتاً على جهازه.
  }
}
