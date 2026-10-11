import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_common.dart';

// ═══════════════════════════════════════════════════════════════
// MONTHLY GRADE BREAKDOWN (main dashboard view)
// Shows how many farmers got each grade (FA..FF) in the selected
// month, as a share of all grades given that month (0 - 100%).
// Source of truth: Firestore `grades` collection
//   grade     -> FA..FF
//   createdAt -> Timestamp when the grade was recorded
// ═══════════════════════════════════════════════════════════════
class MonthlyGradeChart extends StatefulWidget {
  const MonthlyGradeChart({super.key});

  @override
  State<MonthlyGradeChart> createState() => _MonthlyGradeChartState();
}

class _MonthlyGradeChartState extends State<MonthlyGradeChart> {
  int _chartYear = DateTime.now().year;
  int _chartMonth = DateTime.now().month - 1; // 0 = January

  static const _monthFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final wide = AdminLayout.isWide(context);

    final double plotHeight = wide ? 260 : 220;
    const double headroom = 40; // room above 100% for the "% (n)" labels
    final double scaleHeight = plotHeight - headroom;
    const double axisLabelHeight = 30;
    const double yAxisWidth = 42;
    final double barGap = wide ? 10 : 4;

    final now = DateTime.now();
    final isCurrentMonth =
        _chartYear == now.year && _chartMonth == now.month - 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 24 : 16),
      decoration: cardDecoration(),
      child: StreamBuilder<QuerySnapshot>(
        // Live query: only grade records created in the selected month
        stream: FirebaseFirestore.instance
            .collection('grades')
            .where('createdAt',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(DateTime(_chartYear, _chartMonth + 1)),
                isLessThan:
                    Timestamp.fromDate(DateTime(_chartYear, _chartMonth + 2)))
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final counts = List<int>.filled(6, 0);
          int skipped = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final idx = kGradeOrder
                .indexOf((data['grade'] ?? '').toString().toUpperCase());
            if (idx == -1 || data['createdAt'] is! Timestamp) {
              skipped++;
              continue;
            }
            counts[idx]++;
          }

          final total = counts.fold(0, (a, b) => a + b);

          // True average: sum of ranks (FA=1 ... FF=6) / number of records
          int rankSum = 0;
          for (int i = 0; i < 6; i++) {
            rankSum += counts[i] * (i + 1);
          }
          final double? avg = total == 0 ? null : rankSum / total;
          final avgGrade = avg == null
              ? '--'
              : kGradeOrder[avg.round().clamp(1, 6).toInt() - 1];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Grade Breakdown',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 4),
              const Text(
                  'Grades given in the selected month, with the month\'s average grade',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(height: 16),

              // ── Month navigator:  <  January 2026  > ──
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        if (_chartMonth == 0) {
                          _chartMonth = 11;
                          _chartYear--;
                        } else {
                          _chartMonth--;
                        }
                      }),
                    ),
                    SizedBox(
                      width: wide ? 170 : 150,
                      child: Text('${_monthFull[_chartMonth]} $_chartYear',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isCurrentMonth
                          ? null
                          : () => setState(() {
                                if (_chartMonth == 11) {
                                  _chartMonth = 0;
                                  _chartYear++;
                                } else {
                                  _chartMonth++;
                                }
                              }),
                    ),
                  ],
                ),
              ),
              Center(
                child: total == 0
                    ? const Text('No grades recorded this month',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF888888)))
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradeColor(avgGrade).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Average grade: $avgGrade (${avg!.toStringAsFixed(2)})  ·  $total graded',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: gradeColor(avgGrade)),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              if (snapshot.hasError)
                SizedBox(
                  height: plotHeight,
                  child: const EmptyState(
                      icon: Icons.error_outline,
                      message: 'Could not load grade data',
                      sub: 'Check your connection and Firestore rules'),
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                SizedBox(height: plotHeight, child: const AdminLoader())
              else if (total == 0)
                SizedBox(
                  height: plotHeight,
                  child: EmptyState(
                      icon: Icons.bar_chart,
                      message:
                          'No grades in ${_monthFull[_chartMonth]} $_chartYear',
                      sub: 'Use the arrows to view another month'),
                )
              else
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: SizedBox(
                      height: plotHeight + axisLabelHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Y axis: 0 - 100 %
                          SizedBox(
                            width: yAxisWidth,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: plotHeight,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (int t = 0; t <= 100; t += 25)
                                        Positioned(
                                          bottom: scaleHeight * t / 100 - 7,
                                          left: 0,
                                          right: 8,
                                          child: Text('$t',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF888888))),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: axisLabelHeight),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: plotHeight,
                                  child: Stack(
                                    children: [
                                      for (int t = 25; t <= 100; t += 25)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: scaleHeight * t / 100,
                                          child: Container(
                                              height: 1,
                                              color: const Color(0xFFEFEFEF)),
                                        ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                            height: 1,
                                            color: const Color(0xFFD0D0D0)),
                                      ),
                                      Positioned.fill(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: List.generate(6, (i) {
                                            final c = counts[i];
                                            final pct = c / total * 100;
                                            final pctText = pct % 1 == 0
                                                ? pct.toStringAsFixed(0)
                                                : pct.toStringAsFixed(1);
                                            return Expanded(
                                              child: Tooltip(
                                                message:
                                                    '${kGradeOrder[i]}: $c of $total graded ($pctText%)',
                                                child: Padding(
                                                  padding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: barGap),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      if (c > 0) ...[
                                                        FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                              '$pctText%',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: gradeColor(
                                                                      kGradeOrder[
                                                                          i]))),
                                                        ),
                                                        FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text('($c)',
                                                              style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Color(
                                                                      0xFF888888))),
                                                        ),
                                                        const SizedBox(
                                                            height: 3),
                                                        AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      400),
                                                          curve: Curves.easeOut,
                                                          height: scaleHeight *
                                                              pct /
                                                              100,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: gradeColor(
                                                                kGradeOrder[i]),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            6)),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: axisLabelHeight,
                                  child: Row(
                                    children: List.generate(6, (i) {
                                      return Expanded(
                                        child: Center(
                                          child: Text(kGradeOrder[i],
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: gradeColor(
                                                      kGradeOrder[i]))),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Text(
                'Percent = grades of that type ÷ all grades recorded in the month. '
                'Counts in brackets. Data comes from the grades database'
                '${skipped > 0 ? ' ($skipped skipped: invalid grade or date)' : ''}.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ],
          );
        },
      ),
    );
  }
}