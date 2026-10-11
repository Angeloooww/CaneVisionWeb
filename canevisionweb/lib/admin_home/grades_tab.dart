import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';

class GradesTab extends StatelessWidget {
  const GradesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = AdminLayout.pagePad(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoader();
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const EmptyState(
              icon: Icons.workspace_premium_outlined,
              message: 'No grade records yet',
              sub: 'Grade records appear after scans');
        }

        return Padding(
          padding: EdgeInsets.all(pad),
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
            itemCount: docs.length,
            rowBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final grade = (data['grade'] ?? '--').toString().toUpperCase();
              final ts = data['createdAt'];
              String dateStr = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                dateStr = '${dt.month}/${dt.day}/${dt.year}';
              }
              return [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((data['farmerName'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A))),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA))),
                    ],
                  ),
                ),
                txtCell((data['farmId'] ?? '').toString()),
                txtCell((data['graderName'] ?? '').toString()),
                Expanded(
                  flex: 2,
                  child: Text((data['certId'] ?? '').toString(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((data['remarkCode'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A))),
                      Text((data['remarkFull'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),
                ),
                gradeCell(grade),
              ];
            },
          ),
        );
      },
    );
  }
}