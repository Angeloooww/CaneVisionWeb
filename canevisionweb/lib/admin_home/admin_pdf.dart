import 'dart:io' show File, Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'admin_common.dart';

// ── Generic printable table (PDF) ─────────────────────────────
pw.Document buildPdfTable({
  required String title,
  required String subtitle,
  required List<String> headers,
  required List<List<String>> rows,
  List<pw.Widget> topWidgets = const [],
}) {
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    header: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CaneVision',
            style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.green800,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(subtitle,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 10),
      ],
    ),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ),
    build: (ctx) => [
      ...topWidgets,
      if (rows.isEmpty)
        pw.Text('No records found.', style: pw.TextStyle(fontSize: 11))
      else
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColors.green700),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
        ),
    ],
  ));
  return doc;
}

Future<void> printDoc(
    BuildContext context, pw.Document doc, String name) async {
  try {
    await Printing.layoutPdf(
      name: name,
      onLayout: (_) async => doc.save(),
    );
  } catch (e) {
    showAdminSnackBar(context, 'Could not open the print dialog: $e',
        isError: true);
  }
}

// ── Certificate of Quality (PDF) ──────────────────────────────

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

Future<pw.Document> certificatePdf(GradeRec r) async {
  final doc = pw.Document();

  final green = PdfColor.fromInt(0xFF11BD51);
  final orange = PdfColor.fromInt(0xFFE49B0F);
  final grey = PdfColors.grey600;
  final lineColor = PdfColors.grey300;

  final d = r.date;
  final inspection =
      d == null ? '-' : '${_months[d.month - 1]} ${d.day}, ${d.year}';
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final generated =
      '${now.month}/${now.day}/${now.year}, ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

  final trash = r.trashDiscount.isEmpty
      ? '-'
      : (r.trashDiscount.contains('%') ? r.trashDiscount : '${r.trashDiscount}%');

  pw.Widget divider() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Divider(color: lineColor, thickness: 0.6, height: 0));

  pw.Widget infoRow(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k, style: pw.TextStyle(fontSize: 8, color: grey)),
            pw.Flexible(
              child: pw.Text(v.isEmpty ? '-' : v,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Brand
        pw.Row(children: [
          pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
                color: green, borderRadius: pw.BorderRadius.circular(4)),
          ),
          pw.SizedBox(width: 8),
          pw.Text('CaneVision',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 18),

        // Title
        pw.Center(
          child: pw.Column(children: [
            pw.Text('Certificate of Quality',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text('Sugarcane Quality Assessment Report',
                style: pw.TextStyle(fontSize: 8, color: grey)),
            pw.SizedBox(height: 2),
            pw.Text('Certificate ID: ${r.certId.isEmpty ? '-' : r.certId}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ]),
        ),
        divider(),

        // Farmer + grader
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Farmer Information',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  infoRow('Name', r.farmerName),
                  infoRow('Farm ID', r.farmId),
                  infoRow('Inspection Date', inspection),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Graded By',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  infoRow('Quality Grader', r.graderName),
                  infoRow('Email', r.graderEmail),
                ],
              ),
            ),
          ],
        ),
        divider(),

        // Grade bar
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: pw.BoxDecoration(
              color: green, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(r.grade,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.SizedBox(width: 10),
              pw.Text(kGradeLabels[r.grade] ?? '',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Quality parameters
        pw.Text('Quality Parameters',
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: green)),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Trash Discount',
                      style: pw.TextStyle(fontSize: 7, color: grey)),
                  pw.SizedBox(height: 2),
                  pw.Text(trash,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Remarks',
                      style: pw.TextStyle(fontSize: 7, color: grey)),
                  pw.SizedBox(height: 2),
                  pw.Text(r.remarkCode.isEmpty ? '-' : r.remarkCode,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (r.remarkFull.isNotEmpty)
                    pw.Text(r.remarkFull,
                        style: pw.TextStyle(fontSize: 7, color: grey)),
                ],
              ),
            ),
          ],
        ),

        // Operational advisory
        if (r.advisory.isNotEmpty) ...[
          divider(),
          pw.Text('Operational Advisory',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: orange)),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFFAEB),
              border: pw.Border.all(color: orange, width: 0.6),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(r.advisory, style: pw.TextStyle(fontSize: 7)),
          ),
        ],

        pw.SizedBox(height: 18),
        pw.Center(
          child: pw.Column(children: [
            pw.Text('This certificate is digitally generated and verified.',
                style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
            pw.Text('Generated on $generated',
                style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
          ]),
        ),
      ],
    ),
  ));
  return doc;
}

Future<void> printCertificate(BuildContext context, GradeRec r) async {
  try {
    final doc = await certificatePdf(r);
    if (!context.mounted) return;
    await printDoc(context, doc,
        'certificate_${r.certId.isEmpty ? r.id : r.certId}');
  } catch (e) {
    showAdminSnackBar(context, 'Could not build the certificate: $e',
        isError: true);
  }
}

/// Saves any PDF document to a file.
/// Web: normal browser download. Desktop/mobile: "Save as" dialog.
Future<void> downloadDoc(
    BuildContext context, pw.Document doc, String baseName) async {
  try {
    final bytes = await doc.save();
    final fileName = '$baseName.pdf';

    if (kIsWeb) {
      // Browsers choose the download folder themselves (enable
      // "Ask where to save each file" in the browser settings).
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }

    final dynamic saved = await FilePicker.saveFile(
      dialogTitle: 'Save PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes, // required on Android / iOS
    );
    if (saved == null) return; // user cancelled
    // Newer file_picker versions return a Uri, older ones a String path.
    final String path = saved is Uri ? saved.toFilePath() : saved.toString();

    // Windows / macOS / Linux return the chosen path but don't write the file.
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await File(path).writeAsBytes(bytes);
    }
    if (!context.mounted) return;
    showAdminSnackBar(context, 'PDF saved.');
  } catch (e) {
    if (!context.mounted) return;
    showAdminSnackBar(context, 'Could not download the PDF: $e',
        isError: true);
  }
}

/// Downloads the certificate as a PDF file directly (no print dialog).
Future<void> downloadCertificate(BuildContext context, GradeRec r) async {
  try {
    final doc = await certificatePdf(r);
    if (!context.mounted) return;
    await downloadDoc(
        context, doc, 'certificate_${r.certId.isEmpty ? r.id : r.certId}');
  } catch (e) {
    if (!context.mounted) return;
    showAdminSnackBar(context, 'Could not download the certificate: $e',
        isError: true);
  }
}

// ── Per-farmer printable report ───────────────────────────────
Future<void> printFarmerReport(
    BuildContext context, Map<String, dynamic> f) async {
  final farmId = (f['farmId'] ?? '').toString();
  final name = (f['fullName'] ?? '').toString();
  try {
    final snap = await FirebaseFirestore.instance
        .collection('grades')
        .where('farmId', isEqualTo: farmId)
        .get();
    final recs = snap.docs.map((d) => GradeRec.fromDoc(d)).toList()
      ..sort(byDateDesc);

    pw.Widget info(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 80,
                child: pw.Text(k,
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
            pw.Text(v.isEmpty ? '-' : v,
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ]),
        );

    final doc = buildPdfTable(
      title: 'Farmer Grading Report',
      subtitle: 'Generated ${todayString()}',
      topWidgets: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              info('Farmer', name),
              info('Farm ID', farmId),
              info('Contact', (f['phone'] ?? '').toString()),
              info('Email', (f['email'] ?? '').toString()),
              info('Current grade', (f['grade'] ?? '--').toString()),
              info('Records', '${recs.length}'),
            ],
          ),
        ),
      ],
      headers: const ['#', 'Date', 'Cert ID', 'Graded By', 'Remarks', 'Grade'],
      rows: [
        for (int i = 0; i < recs.length; i++)
          [
            '${i + 1}',
            recs[i].dateStr,
            recs[i].certId,
            recs[i].graderName,
            recs[i].remarks,
            recs[i].grade,
          ]
      ],
    );
    if (!context.mounted) return;
    await printDoc(context, doc, 'farmer_report_$farmId');
  } catch (e) {
    showAdminSnackBar(context, 'Could not build the report: $e', isError: true);
  }
}