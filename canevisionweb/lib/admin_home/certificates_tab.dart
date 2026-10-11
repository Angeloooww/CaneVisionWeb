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

  final Stream<QuerySnapshot> _stream = FirebaseFirestore.instance
      .collection('grades')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
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
                                        onTap: () => printCertificate(context, r),
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

  // ── Certificate of Quality (on-screen copy, matches the PDF) ──
  void _showCertificate(GradeRec r) {
    const green = Color(0xFF11BD51);
    const orange = Color(0xFFE49B0F);
    const grey = Color(0xFF888888);

    Widget divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Color(0xFFE6E6E6)));

    Widget infoRow(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k, style: const TextStyle(fontSize: 11, color: grey)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(v.isEmpty ? '-' : v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
              ),
            ],
          ),
        );

    Widget heading(String t, {Color color = const Color(0xFF1A1A1A)}) => Text(t,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color));

    final trash = r.trashDiscount.isEmpty
        ? '-'
        : (r.trashDiscount.contains('%')
            ? r.trashDiscount
            : '${r.trashDiscount}%');
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final generated =
        '${now.month}/${now.day}/${now.year}, ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        color: green, borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(width: 8),
                  const Text('CaneVision',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A))),
                ]),
                const SizedBox(height: 16),

                // Title
                Center(
                  child: Column(children: [
                    const Text('Certificate of Quality',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 3),
                    const Text('Sugarcane Quality Assessment Report',
                        style: TextStyle(fontSize: 11, color: grey)),
                    const SizedBox(height: 2),
                    Text('Certificate ID: ${r.certId.isEmpty ? '-' : r.certId}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFAAAAAA))),
                  ]),
                ),
                divider(),

                // Scanned image
                Container(
                  width: double.infinity,
                  color: const Color(0xFFEAFAF1),
                  child: Center(
                    child: SizedBox(
                      width: 100,
                      height: 130,
                      child: r.imageUrl.startsWith('http')
                          ? Image.network(r.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Text('No image',
                                      style: TextStyle(
                                          fontSize: 11, color: grey))))
                          : const Center(
                              child: Text('No image',
                                  style:
                                      TextStyle(fontSize: 11, color: grey))),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Center(
                    child: Text('Scanned Sugarcane',
                        style:
                            TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)))),
                divider(),

                // Farmer + grader
                LayoutBuilder(builder: (context, c) {
                  final farmer = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading('Farmer Information'),
                      const SizedBox(height: 6),
                      infoRow('Name', r.farmerName),
                      infoRow('Farm ID', r.farmId),
                      infoRow('Inspection Date', r.longDateStr),
                    ],
                  );
                  final grader = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading('Graded By'),
                      const SizedBox(height: 6),
                      infoRow('Quality Grader', r.graderName),
                      infoRow('Email', r.graderEmail),
                    ],
                  );
                  if (c.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [farmer, const SizedBox(height: 12), grader],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: farmer),
                      const SizedBox(width: 24),
                      Expanded(child: grader),
                    ],
                  );
                }),
                divider(),

                // Grade bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                      color: green, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Text(r.grade,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 10),
                      Text(kGradeLabels[r.grade] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quality parameters
                heading('Quality Parameters', color: green),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trash Discount',
                              style: TextStyle(fontSize: 10, color: grey)),
                          const SizedBox(height: 2),
                          Text(trash,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Remarks',
                              style: TextStyle(fontSize: 10, color: grey)),
                          const SizedBox(height: 2),
                          Text(r.remarkCode.isEmpty ? '-' : r.remarkCode,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A))),
                          if (r.remarkFull.isNotEmpty)
                            Text(r.remarkFull,
                                style: const TextStyle(
                                    fontSize: 10, color: grey)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Operational advisory
                if (r.advisory.isNotEmpty) ...[
                  divider(),
                  heading('Operational Advisory', color: orange),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEB),
                      border: Border.all(color: orange, width: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(r.advisory,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF555555))),
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: Column(children: [
                    const Text(
                        'This certificate is digitally generated and verified.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 9, color: Color(0xFFAAAAAA))),
                    Text('Generated on $generated',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFFAAAAAA))),
                  ]),
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
                      onPressed: () => printCertificate(ctx, r),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Print / Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
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