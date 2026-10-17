import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';
import 'monthly_grade_chart.dart';

class DashboardTab extends StatelessWidget {
  /// Called when "View all" is tapped in the Recent Farmers card.
  final VoidCallback onViewFarmers;

  const DashboardTab({super.key, required this.onViewFarmers});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('farmers').snapshots(),
      builder: (context, farmersSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('users').snapshots(),
          builder: (context, usersSnap) {
            return StreamBuilder<QuerySnapshot>(
              // Same query the Monthly Grade Breakdown chart uses for the
              // current month, so the card and the chart always agree.
              stream: firestore
                  .collection('grades')
                  .where('createdAt',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(DateTime(now.year, now.month)),
                      isLessThan:
                          Timestamp.fromDate(DateTime(now.year, now.month + 1)))
                  .snapshots(),
              builder: (context, gradesSnap) {
                final farmers = farmersSnap.hasData
                    ? farmersSnap.data!.docs
                    : <QueryDocumentSnapshot>[];
                final users = usersSnap.hasData
                    ? usersSnap.data!.docs
                    : <QueryDocumentSnapshot>[];
                final gradeDocs = gradesSnap.hasData
                    ? gradesSnap.data!.docs
                    : <QueryDocumentSnapshot>[];

                final graders = users
                    .where((u) =>
                        (u.data() as Map<String, dynamic>)['role'] == 'Grader')
                    .toList();
                final admins = users
                    .where((u) =>
                        (u.data() as Map<String, dynamic>)['role'] == 'Admin')
                    .toList();
                final pendingCount = users
                    .where((u) =>
                        (u.data() as Map<String, dynamic>)['status'] ==
                        'pending')
                    .length;

                final avgGrade = _averageGrade(gradeDocs);
                final pad = AdminLayout.pagePad(context);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overview',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      const Text('System-wide statistics at a glance',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(height: 20),

                      // ── Stats grid (equal-width cards that fill the row) ──
                      LayoutBuilder(builder: (context, c) {
                        const spacing = 16.0;
                        final cols = c.maxWidth >= 900
                            ? 5
                            : c.maxWidth >= 560
                                ? 3
                                : 2;
                        final w = ((c.maxWidth - spacing * (cols - 1)) / cols)
                            .floorToDouble();
                        final cards = [
                          StatCard(
                              icon: Icons.grass_outlined,
                              label: 'Total Farmers',
                              value: farmers.length.toString(),
                              color: const Color(0xFF11BD51)),
                          StatCard(
                              icon: Icons.assignment_outlined,
                              label: 'Total Graders',
                              value: graders.length.toString(),
                              color: const Color(0xFF3498DB)),
                          StatCard(
                              icon: Icons.pending_actions_outlined,
                              label: 'Pending Approval',
                              value: pendingCount.toString(),
                              color: const Color(0xFFFFB300)),
                          StatCard(
                              icon: Icons.manage_accounts_outlined,
                              label: 'Admins',
                              value: admins.length.toString(),
                              color: const Color(0xFF9B59B6)),
                          StatCard(
                              icon: Icons.grading_outlined,
                              label: 'Avg Grade (This Month)',
                              value: avgGrade,
                              color: gradeColor(avgGrade)),
                        ];
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: cards
                              .map((c) => SizedBox(width: w, child: c))
                              .toList(),
                        );
                      }),

                      const SizedBox(height: 32),

                      // ── Chart + Recent farmers (stacks on narrow screens) ──
                      LayoutBuilder(builder: (context, c) {
                        final recent = _buildRecentFarmers(farmers);
                        if (c.maxWidth >= 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                  flex: 3, child: MonthlyGradeChart()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: recent),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            const MonthlyGradeChart(),
                            const SizedBox(height: 16),
                            recent,
                          ],
                        );
                      }),
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

  /// Average grade of this month's records in the `grades` collection.
  /// Skips the same invalid records (bad grade / missing createdAt) that
  /// the Monthly Grade Breakdown chart skips.
  String _averageGrade(List<QueryDocumentSnapshot> gradeDocs) {
    final grades = gradeDocs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((data) => data['createdAt'] is Timestamp)
        .map((data) => (data['grade'] ?? '').toString());
    return rankToGrade(averageGradeRank(grades));
  }

  Widget _buildRecentFarmers(List<QueryDocumentSnapshot> farmers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Farmers',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const Spacer(),
              if (farmers.length > 5)
                GestureDetector(
                  onTap: onViewFarmers,
                  child: const Text('View all',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF11BD51),
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (farmers.isEmpty)
            const EmptyState(
                icon: Icons.people_outline,
                message: 'No farmers yet',
                sub: 'Farmers appear once added')
          else
            ...farmers.take(5).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _RecentFarmerRow(
                name: (data['fullName'] ?? '').toString(),
                farmId: (data['farmId'] ?? '').toString(),
                grade: (data['grade'] ?? '--').toString(),
              );
            }),
        ],
      ),
    );
  }
}

class _RecentFarmerRow extends StatelessWidget {
  final String name;
  final String farmId;
  final String grade;
  const _RecentFarmerRow(
      {required this.name, required this.farmId, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
                Text('Farm ID: $farmId',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GradeBadge(grade),
        ],
      ),
    );
  }
}