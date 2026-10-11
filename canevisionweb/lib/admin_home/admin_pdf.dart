import 'package:cloud_firestore/cloud_firestore.dart';
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

// ── Certificate (PDF) ─────────────────────────────────────────
pw.Document certificatePdf(GradeRec r) {
  final doc = pw.Document();
  pw.Widget line(String label, String value) => pw.Column(children: [
        pw.Text(value.isEmpty ? '-' : value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ]);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(24),
    build: (ctx) => pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: const pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green700, width: 4)),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('CANEVISION',
              style: pw.TextStyle(
                  fontSize: 14,
                  letterSpacing: 3,
                  color: PdfColors.green800,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Certificate of Sugarcane Grading',
              style:
                  pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 18),
          pw.Text('This certifies that the sugarcane of',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text(r.farmerName.isEmpty ? '-' : r.farmerName,
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Farm ID: ${r.farmId.isEmpty ? '-' : r.farmId}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 12),
          pw.Text('has been graded',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(r.grade,
              style: pw.TextStyle(
                  fontSize: 54,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800)),
          if (r.remarkCode.isNotEmpty || r.remarkFull.isNotEmpty)
            pw.Text(
                'Remarks: ${r.remarkCode}${r.remarkFull.isNotEmpty ? ' - ${r.remarkFull}' : ''}',
                style: pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 26),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              line('Graded by', r.graderName),
              line('Date', r.dateStr),
              line('Certificate ID', r.certId),
            ],
          ),
        ],
      ),
    ),
  ));
  return doc;
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