import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';
import 'admin_pdf.dart';

class GradersTab extends StatefulWidget {
  const GradersTab({super.key});

  @override
  State<GradersTab> createState() => _GradersTabState();
}

class _GradersTabState extends State<GradersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  late final Stream<QuerySnapshot> _usersStream =
      _firestore.collection('users').snapshots();
  late final Stream<QuerySnapshot> _gradesStream =
      _firestore.collection('grades').snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────
  Future<void> _deleteUser(String docId, String name) async {
    final ok = await confirmDialog(
      context,
      title: 'Remove User',
      message:
          'Remove $name from the system?\n\nNote: This removes their Firestore record. Their Firebase Auth account remains until deleted from the Firebase console.',
      confirmLabel: 'Remove',
      messageSize: 13,
      messageColor: const Color(0xFF444444),
    );
    if (!ok) return;
    await _firestore.collection('users').doc(docId).delete();
    if (!mounted) return;
    showAdminSnackBar(context, '$name removed.', isError: true);
  }

  Future<void> _approveGrader(String docId, String name) async {
    await _firestore.collection('users').doc(docId).update({'status': 'approved'});
    if (!mounted) return;
    showAdminSnackBar(context, '$name has been approved.');
  }

  Future<void> _rejectGrader(String docId, String name) async {
    final ok = await confirmDialog(
      context,
      title: 'Reject Account',
      message: 'Reject $name\'s registration?',
      confirmLabel: 'Reject',
    );
    if (!ok) return;
    await _firestore.collection('users').doc(docId).update({'status': 'rejected'});
    if (!mounted) return;
    showAdminSnackBar(context, '$name has been rejected.', isError: true);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
          child: Row(
            children: [
              const Text('All Graders',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(width: 16),
              Flexible(
                child: AdminSearchField(
                  controller: _searchController,
                  hint: 'Search grader by name, email or contact',
                  query: _query,
                  maxWidth: 320,
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase().trim()),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoader();
              }
              final docs = snapshot.data?.docs ?? [];
              final allGraders = docs
                  .where((u) =>
                      (u.data() as Map<String, dynamic>)['role'] == 'Grader')
                  .toList();

              bool matches(QueryDocumentSnapshot u) {
                if (_query.isEmpty) return true;
                final d = u.data() as Map<String, dynamic>;
                return ['fullName', 'email', 'contactNumber'].any((k) =>
                    (d[k] ?? '').toString().toLowerCase().contains(_query));
              }

              String statusOf(QueryDocumentSnapshot u) =>
                  ((u.data() as Map<String, dynamic>)['status'] ?? '')
                      .toString();

              final pending = allGraders
                  .where((u) => statusOf(u) == 'pending' && matches(u))
                  .toList();
              final approved = allGraders
                  .where((u) =>
                      statusOf(u) != 'pending' &&
                      statusOf(u) != 'rejected' &&
                      matches(u))
                  .toList();
              final rejected = allGraders
                  .where((u) => statusOf(u) == 'rejected' && matches(u))
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _gradesStream,
                builder: (context, gSnap) {
                  final recs = (gSnap.data?.docs ?? [])
                      .map((d) => GradeRec.fromDoc(d))
                      .toList();

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Pending Approvals ─────────────────────────
                        if (pending.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SectionHeader('Pending Approval', pending.length),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFFB300)
                                          .withOpacity(0.4)),
                                ),
                                child: const Text('Action required',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFFFB300),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: cardDecoration().copyWith(
                              border: Border.all(
                                  color:
                                      const Color(0xFFFFB300).withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < pending.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                        height: 1, color: Color(0xFFF0F0F0)),
                                  _buildPendingRow(pending[i]),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // ── Approved Graders + grade counts ───────────
                        if (approved.isNotEmpty) ...[
                          SectionHeader('Approved Graders', approved.length),
                          const SizedBox(height: 4),
                          const Text(
                              'Number of grades each grader has recorded. Tap "Records" to see the sugarcane they graded.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF888888))),
                          const SizedBox(height: 8),
                          _buildStatsTable(approved, recs),
                          const SizedBox(height: 28),
                        ],

                        // ── Rejected Graders ──────────────────────────
                        if (rejected.isNotEmpty) ...[
                          SectionHeader('Rejected', rejected.length),
                          const SizedBox(height: 8),
                          Container(
                            decoration: cardDecoration(),
                            child: Column(
                              children: [
                                for (int i = 0; i < rejected.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                        height: 1, color: Color(0xFFF0F0F0)),
                                  _buildRejectedRow(rejected[i]),
                                ],
                              ],
                            ),
                          ),
                        ],

                        if (allGraders.isEmpty)
                          const EmptyState(
                              icon: Icons.people_outline,
                              message: 'No graders found',
                              sub:
                                  'Grader accounts will appear here once registered')
                        else if (pending.isEmpty &&
                            approved.isEmpty &&
                            rejected.isEmpty)
                          EmptyState(
                              icon: Icons.search_off,
                              message: 'No graders match "$_query"',
                              sub: 'Try a different search term'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Approved graders table with per-grade counts ──────────────
  Widget _buildStatsTable(
      List<QueryDocumentSnapshot> approved, List<GradeRec> recs) {
    const double minWidth = 800;

    return Container(
      decoration: cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(builder: (context, c) {
          final w = math.max(c.maxWidth, minWidth);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: w,
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF7F7F7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        hdrCell('Grader', flex: 1),
                        hdrFixed('Total', 60, center: true),
                        for (final g in kGradeOrder)
                          hdrFixed(g, 44, color: gradeColor(g), center: true),
                        const SizedBox(width: 12),
                        hdrFixed('Actions', 120, center: true),
                      ],
                    ),
                  ),
                  for (int i = 0; i < approved.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    _buildStatsRow(approved[i], recs),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsRow(QueryDocumentSnapshot doc, List<GradeRec> recs) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['fullName'] ?? '').toString();
    final mine = recsForGrader(recs, doc.id, name);
    final counts = gradeBreakdown(mine);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 18, color: Color(0xFF3498DB)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                      Text((data['email'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF11BD51).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${mine.length}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF11BD51))),
              ),
            ),
          ),
          for (final g in kGradeOrder)
            SizedBox(
              width: 44,
              child: Center(
                child: Text('${counts[g]}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: (counts[g] ?? 0) > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (counts[g] ?? 0) > 0
                            ? gradeColor(g)
                            : const Color(0xFFBBBBBB))),
              ),
            ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showGraderRecords(doc.id, name, recs),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11BD51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Records',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                MiniAction(
                  icon: Icons.delete_outline,
                  tip: 'Remove grader',
                  color: Colors.redAccent,
                  background: const Color(0xFFFFEEEE),
                  onTap: () => _deleteUser(doc.id, name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending row ───────────────────────────────────────────────
  Widget _buildPendingRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['fullName'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final contact = (data['contactNumber'] ?? '').toString();

    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 520;
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline,
                  size: 20, color: Color(0xFFFFB300)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  Text(email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888))),
                  if (contact.isNotEmpty)
                    Text(contact,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA))),
                ],
              ),
            ),
            if (!compact) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Pending',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB300))),
              ),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _approveGrader(doc.id, name),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF11BD51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Approve',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _rejectGrader(doc.id, name),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Reject',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Rejected row ──────────────────────────────────────────────
  Widget _buildRejectedRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['fullName'] ?? '').toString();
    const roleColor = Color(0xFF3498DB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline,
                size: 20, color: roleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Text((data['email'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Rejected',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: roleColor)),
          ),
          const SizedBox(width: 10),
          MiniAction(
            icon: Icons.delete_outline,
            tip: 'Remove user',
            color: Colors.redAccent,
            background: const Color(0xFFFFEEEE),
            onTap: () => _deleteUser(doc.id, name),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GRADER RECORDS DIALOG — sugarcane graded by one grader
  // ═══════════════════════════════════════════════════════════════
  void _showGraderRecords(String uid, String name, List<GradeRec> all) {
    final mine = recsForGrader(all, uid, name)..sort(byDateDesc);
    final counts = gradeBreakdown(mine);
    final screenH = MediaQuery.of(context).size.height;

    // Same PDF is used by both the Download and Print buttons.
    buildDoc() => buildPdfTable(
          title: 'Grader Record - $name',
          subtitle:
              'Generated ${todayString()}  |  Total graded: ${mine.length}  |  ${kGradeOrder.map((g) => '$g: ${counts[g]}').join('  ')}',
          headers: const [
            '#',
            'Date',
            'Farmer',
            'Farm ID',
            'Cert ID',
            'Remarks',
            'Grade'
          ],
          rows: [
            for (int i = 0; i < mine.length; i++)
              [
                '${i + 1}',
                mine[i].dateStr,
                mine[i].farmerName,
                mine[i].farmId,
                mine[i].certId,
                mine[i].remarks,
                mine[i].grade,
              ]
          ],
        );
    final fileBase =
        'grader_record_${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 920, maxHeight: math.min(640, screenH * 0.85)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('$name - Graded Sugarcane Records',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${mine.length} grade record${mine.length == 1 ? '' : 's'} in total',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: kGradeOrder
                      .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: gradeColor(g).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$g: ${counts[g]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: gradeColor(g))),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: mine.isEmpty
                      ? const EmptyState(
                          icon: Icons.grass_outlined,
                          message: 'No grades recorded by this grader yet',
                          sub: 'Records appear after they grade sugarcane')
                      : AdminTable(
                          minWidth: 720,
                          bordered: true,
                          radius: 12,
                          hPad: 16,
                          headerVPad: 10,
                          rowVPad: 10,
                          header: [
                            hdrCell('Date'),
                            hdrCell('Farmer', flex: 3),
                            hdrCell('Farm ID'),
                            hdrCell('Cert ID'),
                            hdrCell('Remarks'),
                            hdrFixed('Grade', 60),
                          ],
                          itemCount: mine.length,
                          rowBuilder: (context, i) {
                            final r = mine[i];
                            return [
                              txtCell(r.dateStr),
                              txtCell(r.farmerName, flex: 3, bold: true),
                              txtCell(r.farmId),
                              txtCell(r.certId, size: 11),
                              txtCell(r.remarkCode),
                              gradeCell(r.grade),
                            ];
                          },
                        ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close',
                          style: TextStyle(color: Color(0xFF888888))),
                    ),
                    // Download as a PDF file
                    ElevatedButton.icon(
                      onPressed: mine.isEmpty
                          ? null
                          : () => downloadDoc(ctx, buildDoc(), fileBase),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11BD51),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    // Open the print dialog
                    OutlinedButton.icon(
                      onPressed: mine.isEmpty
                          ? null
                          : () => printDoc(ctx, buildDoc(), fileBase),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF11BD51),
                        side: const BorderSide(color: Color(0xFF11BD51)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}