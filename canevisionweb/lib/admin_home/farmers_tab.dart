import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';
import 'admin_pdf.dart';

class FarmersTab extends StatefulWidget {
  const FarmersTab({super.key});

  @override
  State<FarmersTab> createState() => _FarmersTabState();
}

class _FarmersTabState extends State<FarmersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteFarmer(String docId, String name) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete Farmer',
      message: 'Remove $name from the system?',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await _firestore.collection('farmers').doc(docId).delete();
    if (!mounted) return;
    showAdminSnackBar(context, '$name removed.', isError: true);
  }

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
              const Text('All Farmers',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(width: 16),
              Flexible(
                child: AdminSearchField(
                  controller: _searchController,
                  hint: 'Search by name, Farm ID, phone or email',
                  query: _query,
                  maxWidth: 320,
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase().trim()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('farmers')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoader();
              }
              final docs = snapshot.data?.docs ?? [];
              final filtered = _query.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      bool has(String k) => (data[k] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_query);
                      return has('fullName') ||
                          has('farmId') ||
                          has('email') ||
                          has('phone');
                    }).toList();

              if (docs.isEmpty) {
                return const EmptyState(
                    icon: Icons.grass_outlined,
                    message: 'No farmers registered',
                    sub: 'Farmers will appear here once added');
              }
              if (filtered.isEmpty) {
                return EmptyState(
                    icon: Icons.search_off,
                    message: 'No results for "$_query"',
                    sub: 'Try a different search term');
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                child: AdminTable(
                  minWidth: 760,
                  header: [
                    hdrCell('Name', flex: 3),
                    hdrCell('Farm ID'),
                    hdrCell('Contact'),
                    hdrCell('Email'),
                    hdrFixed('Grade', 60),
                    const SizedBox(width: 72),
                  ],
                  itemCount: filtered.length,
                  rowBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return [
                      txtCell((data['fullName'] ?? '').toString(),
                          flex: 3, bold: true),
                      txtCell((data['farmId'] ?? '').toString()),
                      txtCell((data['phone'] ?? '').toString()),
                      txtCell((data['email'] ?? '').toString()),
                      gradeCell((data['grade'] ?? '--').toString()),
                      SizedBox(
                        width: 72,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            MiniAction(
                              icon: Icons.print_outlined,
                              tip: 'Print farmer report',
                              onTap: () => printFarmerReport(context, data),
                            ),
                            const SizedBox(width: 6),
                            MiniAction(
                              icon: Icons.delete_outline,
                              tip: 'Delete farmer',
                              color: Colors.redAccent,
                              background: const Color(0xFFFFEEEE),
                              onTap: () => _deleteFarmer(
                                  doc.id, (data['fullName'] ?? '').toString()),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}