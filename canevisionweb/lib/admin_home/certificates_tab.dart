import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_common.dart';
import 'admin_pdf.dart';

class CertificatesTab extends StatefulWidget {
  const CertificatesTab({super.key});

  @override
  State<CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<CertificatesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoader();
        }
        if (snapshot.hasError) {
          return const EmptyState(
              icon: Icons.error_outline,
              message: 'Could not load certificates',
              sub: 'Check your connection and Firestore rules');
        }
        final all =
            (snapshot.data?.docs ?? []).map((d) => GradeRec.fromDoc(d)).toList();

        // Reports (certificates) issued per grader
        final byGrader = <String, int>{};
        for (final r in all) {
          final k = r.graderName.isEmpty ? 'Unknown' : r.graderName;
          byGrader[k] = (byGrader[k] ?? 0) + 1;
        }
        final graderEntries = byGrader.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final filtered = _query.isEmpty
            ? all
            : all.where((r) {
                return r.certId.toLowerCase().contains(_query) ||
                    r.farmerName.toLowerCase().contains(_query) ||
                    r.farmId.toLowerCase().contains(_query) ||
                    r.graderName.toLowerCase().contains(_query);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
              child: Row(
                children: [
                  const Text('Certificates',
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
                    child: Text('${all.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666))),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: AdminSearchField(
                      controller: _searchController,
                      hint: 'Search Cert ID, farmer, Farm ID or grader',
                      query: _query,
                      maxWidth: 320,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase().trim()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Reports done by each grader ───────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports done by each grader',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 10),
                    if (graderEntries.isEmpty)
                      const Text('No reports yet',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888)))
                    else
                      // Capped height so many graders never push the table off-screen
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 96),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: graderEntries
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3498DB)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text('${e.key}: ${e.value}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3498DB))),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: all.isEmpty
                  ? const EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      message: 'No certificates yet',
                      sub: 'Certificates appear after farmers are graded')
                  : filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          message: 'No results for "$_query"',
                          sub: 'Try a different search term')
                      : Padding(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                          child: AdminTable(
                            minWidth: 860,
                            rowVPad: 10,
                            header: [
                              hdrCell('Cert ID'),
                              hdrCell('Farmer', flex: 3),
                              hdrCell('Farm ID'),
                              hdrCell('Graded By'),
                              hdrCell('Date'),
                              hdrFixed('Grade', 60),
                              const SizedBox(width: 100),
                            ],
                            itemCount: filtered.length,
                            rowBuilder: (context, i) {
                              final r = filtered[i];
                              final fileName =
                                  'certificate_${r.certId.isEmpty ? r.id : r.certId}';
                              return [
                                txtCell(r.certId.isEmpty ? '-' : r.certId,
                                    size: 12),
                                txtCell(r.farmerName, flex: 3, bold: true),
                                txtCell(r.farmId),
                                txtCell(r.graderName),
                                txtCell(r.dateStr),
                                gradeCell(r.grade),
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      MiniAction(
                                        icon: Icons.visibility_outlined,
                                        tip: 'View certificate',
                                        onTap: () => _showCertificate(r),
                                      ),
                                      const SizedBox(width: 6),
                                      MiniAction(
                                        icon: Icons.print_outlined,
                                        tip: 'Print / Save PDF',
                                        onTap: () => printDoc(
                                            context, certificatePdf(r), fileName),
                                      ),
                                      const SizedBox(width: 6),
                                      MiniAction(
                                        icon: Icons.copy_outlined,
                                        tip: 'Copy Cert ID',
                                        color: const Color(0xFF3498DB),
                                        onTap: () {
                                          Clipboard.setData(
                                              ClipboardData(text: r.certId));
                                          showAdminSnackBar(
                                              context, 'Cert ID copied.');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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

  // ── Certificate (on-screen copy) ──────────────────────────────
  void _showCertificate(GradeRec r) {
    Widget field(String label, String value) => Column(
          children: [
            Text(value.isEmpty ? '-' : value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ],
        );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF11BD51), width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('CANEVISION',
                          style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF11BD51))),
                      const SizedBox(height: 8),
                      const Text('Certificate of Sugarcane Grading',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      const Text('This certifies that the sugarcane of',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(height: 6),
                      Text(r.farmerName.isEmpty ? '-' : r.farmerName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      Text('Farm ID: ${r.farmId.isEmpty ? '-' : r.farmId}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(height: 10),
                      const Text('has been graded',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      Text(r.grade,
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: gradeColor(r.grade))),
                      if (r.remarkCode.isNotEmpty || r.remarkFull.isNotEmpty)
                        Text(
                            'Remarks: ${r.remarkCode}${r.remarkFull.isNotEmpty ? ' - ${r.remarkFull}' : ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF555555))),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          field('Graded by', r.graderName),
                          field('Date', r.dateStr),
                          field('Certificate ID', r.certId),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close',
                          style: TextStyle(color: Color(0xFF888888))),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => printDoc(
                          ctx,
                          certificatePdf(r),
                          'certificate_${r.certId.isEmpty ? r.id : r.certId}'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}