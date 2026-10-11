import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';
import 'admin_pdf.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 0=Farmers 1=Grading records 2=Grader summary
  int _reportType = 0;
  DateTimeRange? _reportRange;

  static const _labels = ['Farmers', 'Grading Records', 'Grader Summary'];

  // ── Report data ───────────────────────────────────────────────
  ReportData _buildReportData(List<QueryDocumentSnapshot> farmers,
      List<QueryDocumentSnapshot> users, List<GradeRec> recs) {
    final range = _reportRange;
    final inRange = recs.where((r) {
      if (range == null) return true;
      if (r.date == null) return false;
      final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
      return !r.date!.isBefore(range.start) && r.date!.isBefore(end);
    }).toList()
      ..sort(byDateDesc);

    switch (_reportType) {
      case 0:
        final list = farmers
            .map((d) => d.data() as Map<String, dynamic>)
            .toList()
          ..sort((a, b) => (a['fullName'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['fullName'] ?? '').toString().toLowerCase()));
        return ReportData(
          title: 'Farmers Report',
          headers: const ['#', 'Name', 'Farm ID', 'Contact', 'Email', 'Grade'],
          rows: [
            for (int i = 0; i < list.length; i++)
              [
                '${i + 1}',
                (list[i]['fullName'] ?? '').toString(),
                (list[i]['farmId'] ?? '').toString(),
                (list[i]['phone'] ?? '').toString(),
                (list[i]['email'] ?? '').toString(),
                (list[i]['grade'] ?? '--').toString(),
              ]
          ],
        );
      case 1:
        return ReportData(
          title: 'Grading Records Report',
          headers: const [
            '#',
            'Date',
            'Farmer',
            'Farm ID',
            'Cert ID',
            'Graded By',
            'Remarks',
            'Grade'
          ],
          rows: [
            for (int i = 0; i < inRange.length; i++)
              [
                '${i + 1}',
                inRange[i].dateStr,
                inRange[i].farmerName,
                inRange[i].farmId,
                inRange[i].certId,
                inRange[i].graderName,
                inRange[i].remarks,
                inRange[i].grade,
              ]
          ],
        );
      default:
        final graders = users.where((u) {
          final d = u.data() as Map<String, dynamic>;
          return d['role'] == 'Grader' &&
              d['status'] != 'pending' &&
              d['status'] != 'rejected';
        }).toList();
        final rows = <List<String>>[];
        for (int i = 0; i < graders.length; i++) {
          final d = graders[i].data() as Map<String, dynamic>;
          final nm = (d['fullName'] ?? '').toString();
          final mine = recsForGrader(inRange, graders[i].id, nm);
          final c = gradeBreakdown(mine);
          rows.add([
            '${i + 1}',
            nm,
            (d['email'] ?? '').toString(),
            for (final g in kGradeOrder) '${c[g]}',
            '${mine.length}',
          ]);
        }
        return ReportData(
          title: 'Grader Summary Report',
          headers: ['#', 'Grader', 'Email', ...kGradeOrder, 'Total'],
          rows: rows,
        );
    }
  }

  String _rangeLabel() {
    final r = _reportRange;
    if (r == null) return 'All dates';
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${f(r.start)} to ${f(r.end)}';
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('farmers').snapshots(),
      builder: (context, fSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, uSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('grades')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, gSnap) {
                if (fSnap.connectionState == ConnectionState.waiting ||
                    uSnap.connectionState == ConnectionState.waiting ||
                    gSnap.connectionState == ConnectionState.waiting) {
                  return const AdminLoader();
                }
                final recs = (gSnap.data?.docs ?? [])
                    .map((d) => GradeRec.fromDoc(d))
                    .toList();
                final data = _buildReportData(
                    fSnap.data?.docs ?? [], uSnap.data?.docs ?? [], recs);
                final usesRange = _reportType != 0;
                final subtitle = usesRange
                    ? 'Generated ${todayString()}  |  Period: ${_rangeLabel()}  |  ${data.rows.length} row(s)'
                    : 'Generated ${todayString()}  |  ${data.rows.length} row(s)';

                return Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Printable Reports',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      const Text(
                          'Choose a report, preview the table, then print it or save it as PDF.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (int i = 0; i < _labels.length; i++)
                            ChoiceChip(
                              label: Text(_labels[i]),
                              selected: _reportType == i,
                              selectedColor:
                                  const Color(0xFF11BD51).withOpacity(0.2),
                              onSelected: (_) =>
                                  setState(() => _reportType = i),
                            ),
                          OutlinedButton.icon(
                            onPressed: usesRange
                                ? () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 1)),
                                      initialDateRange: _reportRange,
                                    );
                                    if (picked != null) {
                                      setState(() => _reportRange = picked);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.date_range, size: 16),
                            label: Text(
                                usesRange ? _rangeLabel() : 'Date filter n/a'),
                          ),
                          if (usesRange && _reportRange != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _reportRange = null),
                              child: const Text('Clear dates'),
                            ),
                          ElevatedButton.icon(
                            onPressed: () => printDoc(
                              context,
                              buildPdfTable(
                                title: data.title,
                                subtitle: subtitle,
                                headers: data.headers,
                                rows: data.rows,
                              ),
                              data.title.toLowerCase().replaceAll(' ', '_'),
                            ),
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: const Text('Print / Save PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF11BD51),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.title,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A))),
                              const SizedBox(height: 2),
                              Text(subtitle,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF888888))),
                              const SizedBox(height: 12),
                              Expanded(
                                child: data.rows.isEmpty
                                    ? const EmptyState(
                                        icon: Icons.table_chart_outlined,
                                        message: 'No records for this report',
                                        sub: 'Try another report or date range')
                                    : SingleChildScrollView(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingRowHeight: 40,
                                            dataRowMinHeight: 38,
                                            dataRowMaxHeight: 44,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    const Color(0xFFF7F7F7)),
                                            columns: data.headers
                                                .map((h) => DataColumn(
                                                    label: Text(h,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))))
                                                .toList(),
                                            rows: data.rows
                                                .map((r) => DataRow(
                                                    cells: r
                                                        .map((c) => DataCell(
                                                            Text(c,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12))))
                                                        .toList()))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}