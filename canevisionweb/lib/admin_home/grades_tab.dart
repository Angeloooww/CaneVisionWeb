import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';

class GradesTab extends StatefulWidget {
  const GradesTab({super.key});

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Created once. Building a new stream on every keystroke made the list
  // reload (blink) and the search box lose focus.
  final Stream<QuerySnapshot> _stream = FirebaseFirestore.instance
      .collection('grades')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(GradeRec r) {
    if (_query.isEmpty) return true;
    return [
      r.farmerName,
      r.farmId,
      r.graderName,
      r.certId,
      r.grade,
      r.remarkCode,
      r.remarkFull,
      r.dateStr,
    ].any((v) => v.toLowerCase().contains(_query));
  }

  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return StreamBuilder<QuerySnapshot>(
      // No limit, so search covers every grade record, not just the latest.
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoader();
        }
        if (snapshot.hasError) {
          return const EmptyState(
              icon: Icons.error_outline,
              message: 'Could not load grade records',
              sub: 'Check your connection and Firestore rules');
        }

        final all =
            (snapshot.data?.docs ?? []).map((d) => GradeRec.fromDoc(d)).toList();
        final filtered = all.where(_matches).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
              child: Row(
                children: [
                  const Text('Grade Records',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        _query.isEmpty
                            ? '${all.length}'
                            : '${filtered.length} of ${all.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666))),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: AdminSearchField(
                      controller: _searchController,
                      hint: 'Search farmer, Farm ID, grader, Cert ID or grade',
                      query: _query,
                      maxWidth: 360,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase().trim()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: all.isEmpty
                  ? const EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      message: 'No grade records yet',
                      sub: 'Grade records appear after scans')
                  : filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          message: 'No results for "$_query"',
                          sub: 'Try a different search term')
                      : Padding(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                          child: AdminTable(
                            minWidth: 760,
                            header: [
                              hdrCell('Farmer', flex: 3),
                              hdrCell('Farm ID'),
                              hdrCell('Graded By'),
                              hdrCell('Cert ID'),
                              hdrCell('Remarks'),
                              hdrFixed('Grade', 60),
                            ],
                            itemCount: filtered.length,
                            rowBuilder: (context, index) {
                              final r = filtered[index];
                              final d = r.date;
                              final dateStr = d == null
                                  ? ''
                                  : '${d.month}/${d.day}/${d.year}';
                              return [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.farmerName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1A1A1A))),
                                      if (dateStr.isNotEmpty)
                                        Text(dateStr,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFAAAAAA))),
                                    ],
                                  ),
                                ),
                                txtCell(r.farmId),
                                txtCell(r.graderName),
                                Expanded(
                                  flex: 2,
                                  child: Text(r.certId,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF888888))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.remarkCode,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1A1A1A))),
                                      Text(r.remarkFull,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF888888))),
                                    ],
                                  ),
                                ),
                                gradeCell(r.grade),
                              ];
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}