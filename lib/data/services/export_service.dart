import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import 'activity_service.dart';

/// FR-2.6: export is Admin-only. Both entry points below re-check
/// `actor.isAdmin` before doing anything, in addition to the screen-level
/// gating in the UI — Security Rules don't have a concept of "export" as
/// an action, so this check happening in Dart is the actual gate here
/// (the underlying reads are still subject to `can('view')` either way).
class ExportService {
  final ActivityService _activity = ActivityService();

  Future<File> exportToExcel(List<Customer> customers, AppUser actor) async {
    if (!actor.isAdmin) throw Exception('Only Admin can export customer data.');

    final book = xls.Excel.createExcel();
    final sheet = book['Customers'];
    book.setDefaultSheet('Customers');

    final headers = ['Name', 'Phone', 'CNIC', 'Account Number', 'Account Type', 'Date Opened', 'Address', 'Notes'];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final c in customers) {
      sheet.appendRow([
        xls.TextCellValue(c.name),
        xls.TextCellValue(c.phone),
        xls.TextCellValue(c.cnic),
        xls.TextCellValue(c.accountNumber),
        xls.TextCellValue(c.accountType),
        xls.TextCellValue(c.dateOpened != null ? DateFormat('yyyy-MM-dd').format(c.dateOpened!) : ''),
        xls.TextCellValue(c.address ?? ''),
        xls.TextCellValue(c.notes ?? ''),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cms_customers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(book.encode()!);

    await _activity.log(action: ActivityAction.export, targetId: 'excel:${customers.length}_records', actor: actor);
    return file;
  }

  Future<File> exportToPdf(List<Customer> customers, AppUser actor) async {
    if (!actor.isAdmin) throw Exception('Only Admin can export customer data.');

    final doc = pw.Document();
    const headers = ['Name', 'Phone', 'CNIC', 'Account No.', 'Type'];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('CMS — Customer List', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Exported ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: customers
                .map((c) => [c.name, c.phone, c.cnic, c.accountNumber, c.accountType])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B57)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 24,
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cms_customers_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());

    await _activity.log(action: ActivityAction.export, targetId: 'pdf:${customers.length}_records', actor: actor);
    return file;
  }

  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
}
