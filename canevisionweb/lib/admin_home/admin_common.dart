import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// Shared constants, models, helpers and reusable widgets used by
// every admin tab.
// ═══════════════════════════════════════════════════════════════

const List<String> kGradeOrder = ['FA', 'FB', 'FC', 'FD', 'FE', 'FF'];

Color gradeColor(String grade) {
  switch (grade.toUpperCase()) {
    case 'FA':
      return const Color(0xFF27AE60);
    case 'FB':
      return const Color(0xFF2ECC71);
    case 'FC':
      return const Color(0xFFF39C12);
    case 'FD':
      return const Color(0xFFE67E22);
    case 'FE':
      return const Color(0xFFE74C3C);
    case 'FF':
      return const Color(0xFF922B21);
    default:
      return const Color(0xFFAAAAAA);
  }
}

/// Central place for responsive sizing so every tab uses the same spacing.
class AdminLayout {
  static const double wideBreakpoint = 800;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > wideBreakpoint;

  /// Outer page padding: 28 on desktop, 16 on small screens.
  static double pagePad(BuildContext context) => isWide(context) ? 28 : 16;
}

BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))
      ],
    );

// ── Snackbar / dialogs ─────────────────────────────────────────
void showAdminSnackBar(BuildContext context, String msg,
    {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? Colors.redAccent : const Color(0xFF11BD51),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  double messageSize = 14,
  Color messageColor = const Color(0xFF555555),
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Text(message,
          style: TextStyle(fontSize: messageSize, color: messageColor)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              const Text('Cancel', style: TextStyle(color: Color(0xFF888888))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: const TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return res == true;
}

// ── Grade record model ─────────────────────────────────────────
/// One document from the Firestore "grades" collection.
class GradeRec {
  final String id;
  final String farmerName;
  final String farmId;
  final String graderName;
  final String graderId;
  final String certId;
  final String remarkCode;
  final String remarkFull;
  final String grade;
  final DateTime? date;

  GradeRec({
    required this.id,
    required this.farmerName,
    required this.farmId,
    required this.graderName,
    required this.graderId,
    required this.certId,
    required this.remarkCode,
    required this.remarkFull,
    required this.grade,
    required this.date,
  });

  factory GradeRec.fromDoc(QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    final ts = m['createdAt'];
    return GradeRec(
      id: d.id,
      farmerName: (m['farmerName'] ?? '').toString(),
      farmId: (m['farmId'] ?? '').toString(),
      graderName: (m['graderName'] ?? '').toString(),
      graderId: (m['graderId'] ?? '').toString(),
      certId: (m['certId'] ?? '').toString(),
      remarkCode: (m['remarkCode'] ?? '').toString(),
      remarkFull: (m['remarkFull'] ?? '').toString(),
      grade: (m['grade'] ?? '--').toString().toUpperCase(),
      date: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String get dateStr {
    final d = date;
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get remarks => '$remarkCode $remarkFull'.trim();
}

class ReportData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  ReportData({required this.title, required this.headers, required this.rows});
}

// ── Grade helpers ──────────────────────────────────────────────
Map<String, int> gradeBreakdown(List<GradeRec> rs) {
  final m = <String, int>{for (final g in kGradeOrder) g: 0};
  for (final r in rs) {
    if (m.containsKey(r.grade)) m[r.grade] = m[r.grade]! + 1;
  }
  return m;
}

/// Grade records belonging to one grader. Matches on graderId when the
/// record has one, otherwise falls back to the grader's name.
List<GradeRec> recsForGrader(List<GradeRec> all, String uid, String name) {
  final n = name.trim().toLowerCase();
  return all.where((r) {
    if (r.graderId.isNotEmpty) return r.graderId == uid;
    return r.graderName.trim().toLowerCase() == n;
  }).toList();
}

int byDateDesc(GradeRec a, GradeRec b) =>
    (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970));

String todayString() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════

class AdminLoader extends StatelessWidget {
  const AdminLoader({super.key});

  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(
          color: Color(0xFF11BD51), strokeWidth: 2.5));
}

class GradeBadge extends StatelessWidget {
  final String grade;
  const GradeBadge(this.grade, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gradeColor(grade),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(grade,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

/// Fixed-width table cell that keeps the badge at its natural size
/// instead of stretching it across the whole column.
Widget gradeCell(String grade, {double width = 60}) => SizedBox(
    width: width,
    child: Align(alignment: Alignment.centerLeft, child: GradeBadge(grade)));

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.message,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFFCCCCCC)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const SectionHeader(this.title, this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF666666))),
        ),
      ],
    );
  }
}

/// Search box. Shrinks on small screens instead of overflowing; put it
/// inside a [Flexible] when used in a Row.
class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String query;
  final ValueChanged<String> onChanged;
  final double maxWidth;

  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.query,
    required this.onChanged,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFBBBBBB), size: 18),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFFBBBBBB), size: 16),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF11BD51), width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Small square icon button (28x28) used in table rows.
class MiniAction extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final Color color;
  final Color? background;

  const MiniAction({
    super.key,
    required this.icon,
    required this.tip,
    required this.onTap,
    this.color = const Color(0xFF11BD51),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: background ?? color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table cells ────────────────────────────────────────────────
Widget hdrCell(String t, {int flex = 2}) => Expanded(
    flex: flex,
    child: Text(t,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF888888))));

Widget hdrFixed(String t, double width, {Color? color, bool center = false}) =>
    SizedBox(
        width: width,
        child: Text(t,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF888888))));

Widget txtCell(String t,
        {int flex = 2, bool bold = false, double size = 13}) =>
    Expanded(
        flex: flex,
        child: Text(t,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: size,
                fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
                color:
                    bold ? const Color(0xFF1A1A1A) : const Color(0xFF555555))));

/// Scrollable table card: header + list of rows. Keeps a minimum width and
/// scrolls sideways on small screens instead of overflowing. Must be placed
/// in a parent with bounded height (e.g. inside an Expanded).
class AdminTable extends StatelessWidget {
  final double minWidth;
  final List<Widget> header;
  final int itemCount;
  final List<Widget> Function(BuildContext context, int index) rowBuilder;
  final bool bordered;
  final double radius;
  final double hPad;
  final double headerVPad;
  final double rowVPad;

  const AdminTable({
    super.key,
    required this.minWidth,
    required this.header,
    required this.itemCount,
    required this.rowBuilder,
    this.bordered = false,
    this.radius = 16,
    this.hPad = 20,
    this.headerVPad = 12,
    this.rowVPad = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bordered
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(radius))
          : cardDecoration(radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth < minWidth ? minWidth : c.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: w,
              height: c.maxHeight,
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF7F7F7),
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad, vertical: headerVPad),
                    child: Row(children: header),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: itemCount,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: rowVPad),
                        child: Row(children: rowBuilder(context, i)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}