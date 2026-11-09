import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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

    final headers = [
      'Name',
      'Account Title',
      'Phone',
      'Email',
      'CNIC',
      'Account Number',
      'IBN No.',
      'Account Type',
      'Gender',
      'Status',
      'Date Opened',
      'Address',
      'Notes'
    ];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final c in customers) {
      sheet.appendRow([
        xls.TextCellValue(c.name),
        xls.TextCellValue(c.accountTitle),
        xls.TextCellValue(c.phone),
        xls.TextCellValue(c.email ?? ''),
        xls.TextCellValue(c.cnic),
        xls.TextCellValue(c.accountNumber),
        xls.TextCellValue(c.ibnNo),
        xls.TextCellValue(c.accountType),
        xls.TextCellValue(c.gender ?? ''),
        xls.TextCellValue(c.status),
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
    const headers = ['Name', 'Account Title', 'Phone', 'CNIC', 'Account No.', 'IBN No.', 'Status'];

    // Branch Analytics summary calculations
    final activeCount = customers.where((c) => c.status.toLowerCase() == 'active').length;
    final dormantCount = customers.where((c) => c.status.toLowerCase() == 'dormant').length;
    final blockedCount = customers.where((c) => c.status.toLowerCase() == 'blocked').length;

    final savingsCount = customers.where((c) => c.accountType.toLowerCase().contains('saving')).length;
    final currentCount = customers.where((c) => c.accountType.toLowerCase().contains('current')).length;
    final businessCount = customers.where((c) => c.accountType.toLowerCase().contains('business')).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ── EXECUTIVE REPORT HEADER ──
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF022B24),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CMS — BRANCH AUDIT & CUSTOMER REPORT',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 2),
                    pw.Text('CONFIDENTIAL BANKING INTELLIGENCE DIGEST',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFD4AF37))),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                    pw.Text('Auditor: ${actor.name}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ── EXECUTIVE METRICS SUMMARY TILES ──
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF1F5F9),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL RECORDS', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('${customers.length}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0FDF4),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ACTIVE / DORMANT / BLOCKED', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('$activeCount / $dormantCount / $blockedCount', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF16A34A))),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFEFF6FF),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SAVINGS / CURRENT / BUSINESS', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('$savingsCount / $currentCount / $businessCount', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2563EB))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── DATA TABLE ──
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: customers
                .map((c) => [c.name, c.accountTitle, c.phone, c.cnic, c.accountNumber, c.ibnNo, c.status])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B57)),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellHeight: 20,
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cms_executive_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());

    await _activity.log(action: ActivityAction.export, targetId: 'pdf_digest:${customers.length}_records', actor: actor);
    return file;
  }

  /// Full-fidelity JSON database backup for disaster recovery.
  /// Captures all customer records, timestamps, and fields in structured JSON.
  Future<File> exportToJsonBackup(List<Customer> customers, AppUser actor) async {
    if (!actor.isAdmin) throw Exception('Only Admin can export database backups.');

    final backupPayload = {
      'system': 'CMS Customer Management System',
      'version': '1.0.0',
      'backupTimestamp': DateTime.now().toIso8601String(),
      'exportedBy': actor.email ?? actor.name,
      'actorUid': actor.uid,
      'totalRecords': customers.length,
      'customers': customers
          .map((c) => {
                'accountNumber': c.accountNumber,
                'accountTitle': c.accountTitle,
                'name': c.name,
                'phone': c.phone,
                'cnic': c.cnic,
                'ibnNo': c.ibnNo,
                'accountType': c.accountType,
                'status': c.status,
                'gender': c.gender,
                'email': c.email,
                'address': c.address,
                'notes': c.notes,
                'dateOpened': c.dateOpened?.toIso8601String(),
                'createdBy': c.createdBy,
                'createdAt': c.createdAt?.toIso8601String(),
                'updatedBy': c.updatedBy,
                'updatedAt': c.updatedAt?.toIso8601String(),
              })
          .toList(),
    };

    // Calculate cryptographic SHA-256 integrity hash over records payload
    final rawBytes = utf8.encode(jsonEncode(backupPayload['customers']));
    final sha256Digest = sha256.convert(rawBytes).toString();
    backupPayload['integritySha256'] = sha256Digest;

    final jsonContent = const JsonEncoder.withIndent('  ').convert(backupPayload);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cms_backup_vault_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path);
    await file.writeAsString(jsonContent);

    await _activity.log(
      action: ActivityAction.export,
      targetId: 'backup_json:${customers.length}_records:sha256_${sha256Digest.substring(0, 8)}',
      actor: actor,
    );
    return file;
  }

  /// Calculates SHA-256 fingerprint of any exported file for audit verification
  Future<String> calculateFileSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
}
