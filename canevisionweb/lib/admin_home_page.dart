import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedTab = 0; // 0=Dashboard 1=Farmers 2=Graders 3=Grades

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _farmerSearchController =
      TextEditingController();
  String _farmerQuery = '';

  @override
  void initState() {
    super.initState();
    _farmerSearchController.addListener(() {
      setState(
          () => _farmerQuery = _farmerSearchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _farmerSearchController.dispose();
    super.dispose();
  }

  Color _gradeColor(String grade) {
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

  // ── Logout ────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        );
      }
    }
  }

  // ── Delete Farmer ─────────────────────────────────────────────
  Future<void> _deleteFarmer(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Farmer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Remove $name from the system?',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('farmers').doc(docId).delete();
      _showSnackBar('$name removed.', isError: true);
    }
  }

  // ── Delete User ───────────────────────────────────────────────
  Future<void> _deleteUser(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove User',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
            'Remove $name from the system?\n\nNote: This removes their Firestore record. Their Firebase Auth account remains until deleted from the Firebase console.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('users').doc(docId).delete();
      _showSnackBar('$name removed.', isError: true);
    }
  }

  // ── Approve Grader ───────────────────────────────────────────
  Future<void> _approveGrader(String docId, String name) async {
    await _firestore.collection('users').doc(docId).update({'status': 'approved'});
    _showSnackBar('$name has been approved.');
  }

  // ── Reject Grader ─────────────────────────────────────────────
  Future<void> _rejectGrader(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Account',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Reject $name\'s registration?',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('users').doc(docId).update({'status': 'rejected'});
      _showSnackBar('$name has been rejected.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF11BD51),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final adminName =
        _auth.currentUser?.displayName ?? 'Admin';
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────
          if (isWide) _buildSidebar(adminName),

          // ── Main Content ───────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                _buildTopBar(adminName, isWide),

                // ── Mobile tab bar ────────────────────────────────
                if (!isWide) _buildMobileTabBar(),

                // ── Page content ──────────────────────────────────
                Expanded(
                  child: _selectedTab == 0
                      ? _buildDashboard()
                      : _selectedTab == 1
                          ? _buildFarmersTab()
                          : _selectedTab == 2
                              ? _buildGradersTab()
                              : _buildGradesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────
  Widget _buildSidebar(String adminName) {
    final tabs = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.grass_outlined, 'label': 'Farmers'},
      {'icon': Icons.people_outline, 'label': 'Graders'},
      {'icon': Icons.workspace_premium_outlined, 'label': 'Grades'},
    ];

    return Container(
      width: 220,
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF11BD51), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.grass,
                          color: Color(0xFF11BD51), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('CaneVision',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('MENU',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF666688),
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 8),

          // Nav items
          ...tabs.asMap().entries.map((e) {
            final i = e.key;
            final tab = e.value;
            final isActive = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF11BD51).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(tab['icon'] as IconData,
                        size: 18,
                        color: isActive
                            ? const Color(0xFF11BD51)
                            : const Color(0xFF888899)),
                    const SizedBox(width: 10),
                    Text(tab['label'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF888899))),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // Admin info + logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11BD51).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts,
                        size: 18, color: Color(0xFF11BD51)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adminName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: const Icon(Icons.logout,
                        size: 16, color: Color(0xFF888899)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────
  Widget _buildTopBar(String adminName, bool isWide) {
    final tabTitles = ['Dashboard', 'Farmers', 'Graders', 'Grades'];
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(tabTitles[_selectedTab],
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const Spacer(),
          if (!isWide) ...[
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 15, color: Colors.redAccent),
                    SizedBox(width: 5),
                    Text('Logout',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ADMIN',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mobile Tab Bar ────────────────────────────────────────────
  Widget _buildMobileTabBar() {
    final tabs = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.grass_outlined, 'label': 'Farmers'},
      {'icon': Icons.people_outline, 'label': 'Graders'},
      {'icon': Icons.workspace_premium_outlined, 'label': 'Grades'},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isActive = _selectedTab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF11BD51).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? Border.all(
                          color: const Color(0xFF11BD51), width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value['icon'] as IconData,
                        size: 18,
                        color: isActive
                            ? const Color(0xFF11BD51)
                            : const Color(0xFF888888)),
                    const SizedBox(height: 3),
                    Text(e.value['label'] as String,
                        style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? const Color(0xFF11BD51)
                                : const Color(0xFF888888),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('farmers').snapshots(),
      builder: (context, farmersSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, usersSnap) {
            final farmers = farmersSnap.hasData
                ? farmersSnap.data!.docs
                : <QueryDocumentSnapshot>[];
            final users = usersSnap.hasData
                ? usersSnap.data!.docs
                : <QueryDocumentSnapshot>[];

            final graders = users
                .where((u) =>
                    (u.data() as Map<String, dynamic>)['role'] == 'Grader')
                .toList();
            final admins = users
                .where((u) =>
                    (u.data() as Map<String, dynamic>)['role'] == 'Admin')
                .toList();

            final Map<String, int> gradeCounts = {
              'FA': 0, 'FB': 0, 'FC': 0,
              'FD': 0, 'FE': 0, 'FF': 0,
            };
            for (final doc in farmers) {
              final data = doc.data() as Map<String, dynamic>;
              final g = (data['grade'] ?? '--').toString().toUpperCase();
              if (gradeCounts.containsKey(g)) {
                gradeCounts[g] = gradeCounts[g]! + 1;
              }
            }
            final gradedCount =
                gradeCounts.values.fold(0, (a, b) => a + b);

            const gradeRank = {
              'FA': 1, 'FB': 2, 'FC': 3,
              'FD': 4, 'FE': 5, 'FF': 6,
            };
            const rankToGrade = {
              1: 'FA', 2: 'FB', 3: 'FC',
              4: 'FD', 5: 'FE', 6: 'FF',
            };
            String avgGrade = '--';
            if (gradedCount > 0) {
              final graded = farmers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return gradeRank.containsKey(
                    (data['grade'] ?? '').toString().toUpperCase());
              }).toList();
              if (graded.isNotEmpty) {
                final total = graded.fold<int>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final g = (data['grade'] ?? '').toString().toUpperCase();
                  return sum + (gradeRank[g] ?? 0);
                });
                final avg = (total / graded.length).round().clamp(1, 6);
                avgGrade = rankToGrade[avg] ?? '--';
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
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
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  const SizedBox(height: 20),

                  // ── Stats Grid ────────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          icon: Icons.grass_outlined,
                          label: 'Total Farmers',
                          value: farmers.length.toString(),
                          color: const Color(0xFF11BD51)),
                      _buildStatCard(
                          icon: Icons.assignment_outlined,
                          label: 'Total Graders',
                          value: graders.length.toString(),
                          color: const Color(0xFF3498DB)),
                      _buildStatCard(
                          icon: Icons.pending_actions_outlined,
                          label: 'Pending Approval',
                          value: users
                              .where((u) =>
                                  (u.data() as Map<String, dynamic>)['status'] ==
                                  'pending')
                              .length
                              .toString(),
                          color: const Color(0xFFFFB300)),
                      _buildStatCard(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Admins',
                          value: admins.length.toString(),
                          color: const Color(0xFF9B59B6)),
                      _buildStatCard(
                          icon: Icons.grading_outlined,
                          label: 'Avg Grade',
                          value: avgGrade,
                          color: _gradeColor(avgGrade)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Grade Distribution ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Grade Distribution',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A))),
                              const SizedBox(height: 4),
                              Text(
                                  '$gradedCount of ${farmers.length} farmers graded',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888))),
                              const SizedBox(height: 20),
                              if (farmers.isEmpty)
                                _buildEmptyState(
                                    icon: Icons.bar_chart,
                                    message: 'No grade data yet',
                                    sub: 'Grades appear after scans')
                              else
                                ...gradeCounts.entries.map((entry) {
                                  final grade = entry.key;
                                  final count = entry.value;
                                  final pct = farmers.isEmpty
                                      ? 0.0
                                      : count / farmers.length;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: _gradeColor(grade),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(grade,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 10,
                                              backgroundColor:
                                                  const Color(0xFFF0F0F0),
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                _gradeColor(grade),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 24,
                                          child: Text('$count',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      Color(0xFF444444))),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ── Recent Farmers ──────────────────────
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ],
                          ),
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
                                      onTap: () => setState(
                                          () => _selectedTab = 1),
                                      child: const Text('View all',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF11BD51),
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (farmers.isEmpty)
                                _buildEmptyState(
                                    icon: Icons.people_outline,
                                    message: 'No farmers yet',
                                    sub: 'Farmers appear once added')
                              else
                                ...farmers.take(5).map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildFarmerRow(
                                    name: data['fullName'] ?? '',
                                    farmId: data['farmId'] ?? '',
                                    grade: data['grade'] ?? '--',
                                    showDelete: false,
                                    docId: doc.id,
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FARMERS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFarmersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              const Text('All Farmers',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _farmerSearchController,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    hintText: 'Search by name, Farm ID, phone or email',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: Color(0xFFBBBBBB)),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFFBBBBBB), size: 18),
                    suffixIcon: _farmerQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFFBBBBBB), size: 16),
                            onPressed: () =>
                                _farmerSearchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.15), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF11BD51), width: 1.5),
                    ),
                  ),
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
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF11BD51), strokeWidth: 2.5));
              }
              final docs = snapshot.data?.docs ?? [];
              final filtered = _farmerQuery.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['fullName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final farmId = (data['farmId'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email =
                          (data['email'] ?? '').toString().toLowerCase();
                      final phone =
                          (data['phone'] ?? '').toString().toLowerCase();
                      return name.contains(_farmerQuery) ||
                          farmId.contains(_farmerQuery) ||
                          email.contains(_farmerQuery) ||
                          phone.contains(_farmerQuery);
                    }).toList();

              if (docs.isEmpty) {
                return _buildEmptyState(
                    icon: Icons.grass_outlined,
                    message: 'No farmers registered',
                    sub: 'Farmers will appear here once added');
              }
              if (filtered.isEmpty) {
                return _buildEmptyState(
                    icon: Icons.search_off,
                    message: 'No results for "$_farmerQuery"',
                    sub: 'Try a different search term');
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Name',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF888888)))),
                          Expanded(
                              flex: 2,
                              child: Text('Farm ID',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF888888)))),
                          Expanded(
                              flex: 2,
                              child: Text('Contact',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF888888)))),
                          Expanded(
                              flex: 2,
                              child: Text('Email',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF888888)))),
                          SizedBox(
                              width: 60,
                              child: Text('Grade',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF888888)))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(data['fullName'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(data['farmId'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF555555))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(data['phone'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF555555))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(data['email'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF555555))),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: _buildGradeBadge(
                                      data['grade'] ?? '--'),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: GestureDetector(
                                    onTap: () => _deleteFarmer(
                                        doc.id, data['fullName'] ?? ''),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEEEE),
                                        borderRadius:
                                            BorderRadius.circular(7),
                                      ),
                                      child: const Icon(
                                          Icons.delete_outline,
                                          size: 15,
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GRADERS TAB — with Pending / Approved sections
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGradersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF11BD51), strokeWidth: 2.5));
        }
        final docs = snapshot.data?.docs ?? [];
        final allGraders = docs
            .where((u) =>
                (u.data() as Map<String, dynamic>)['role'] == 'Grader')
            .toList();

        final pending = allGraders
            .where((u) =>
                (u.data() as Map<String, dynamic>)['status'] == 'pending')
            .toList();
        final approved = allGraders
            .where((u) =>
                (u.data() as Map<String, dynamic>)['status'] != 'pending' &&
                (u.data() as Map<String, dynamic>)['status'] != 'rejected')
            .toList();
        final rejected = allGraders
            .where((u) =>
                (u.data() as Map<String, dynamic>)['status'] == 'rejected')
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pending Approvals ───────────────────────────────
              if (pending.isNotEmpty) ...[
                Row(
                  children: [
                    _buildSectionHeader('Pending Approval', pending.length),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFFFB300).withOpacity(0.4)),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFFFB300).withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: pending.asMap().entries.map((e) {
                      final doc = e.value;
                      final data = doc.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          if (e.key > 0)
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          _buildPendingRow(
                            name: data['fullName'] ?? '',
                            email: data['email'] ?? '',
                            contact: data['contactNumber'] ?? '',
                            docId: doc.id,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Approved Graders ────────────────────────────────
              if (approved.isNotEmpty) ...[
                _buildSectionHeader('Approved Graders', approved.length),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: approved.asMap().entries.map((e) {
                      final doc = e.value;
                      final data = doc.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          if (e.key > 0)
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          _buildUserRow(
                            name: data['fullName'] ?? '',
                            email: data['email'] ?? '',
                            role: 'Grader',
                            docId: doc.id,
                            isCurrentUser: false,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Rejected Graders ────────────────────────────────
              if (rejected.isNotEmpty) ...[
                _buildSectionHeader('Rejected', rejected.length),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: rejected.asMap().entries.map((e) {
                      final doc = e.value;
                      final data = doc.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          if (e.key > 0)
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          _buildUserRow(
                            name: data['fullName'] ?? '',
                            email: data['email'] ?? '',
                            role: 'Rejected',
                            docId: doc.id,
                            isCurrentUser: false,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],

              if (allGraders.isEmpty)
                _buildEmptyState(
                    icon: Icons.people_outline,
                    message: 'No graders found',
                    sub: 'Grader accounts will appear here once registered'),
            ],
          ),
        );
      },
    );
  }

  // ── Pending Row ───────────────────────────────────────────────
  Widget _buildPendingRow({
    required String name,
    required String email,
    required String contact,
    required String docId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
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
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
                if (contact.isNotEmpty)
                  Text(contact,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          // Approve button
          GestureDetector(
            onTap: () => _approveGrader(docId, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          // Reject button
          GestureDetector(
            onTap: () => _rejectGrader(docId, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
  }

  // ═══════════════════════════════════════════════════════════════
  // GRADES TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGradesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('grades')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF11BD51), strokeWidth: 2.5));
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
              icon: Icons.workspace_premium_outlined,
              message: 'No grade records yet',
              sub: 'Grade records appear after scans');
        }

        return Container(
          margin: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Farmer',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                    Expanded(
                        flex: 2,
                        child: Text('Farm ID',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                    Expanded(
                        flex: 2,
                        child: Text('Graded By',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                    Expanded(
                        flex: 2,
                        child: Text('Cert ID',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                    Expanded(
                        flex: 2,
                        child: Text('Remarks',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                    SizedBox(
                        width: 60,
                        child: Text('Grade',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888)))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final grade =
                        (data['grade'] ?? '--').toString().toUpperCase();
                    final ts = data['createdAt'];
                    String dateStr = '';
                    if (ts != null) {
                      final dt = (ts as dynamic).toDate() as DateTime;
                      dateStr =
                          '${dt.month}/${dt.day}/${dt.year}';
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['farmerName'] ?? '',
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
                          Expanded(
                            flex: 2,
                            child: Text(data['farmId'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF555555))),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(data['graderName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF555555))),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(data['certId'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888888))),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['remarkCode'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A1A))),
                                Text(data['remarkFull'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888))),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: 60,
                              child: _buildGradeBadge(grade)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
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
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
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

  Widget _buildFarmerRow({
    required String name,
    required String farmId,
    required String grade,
    required bool showDelete,
    required String docId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
                Text('Farm ID: $farmId',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
          _buildGradeBadge(grade),
          if (showDelete) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteFarmer(docId, name),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 15, color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRow({
    required String name,
    required String email,
    required String role,
    required String docId,
    required bool isCurrentUser,
  }) {
    final isAdmin = role == 'Admin';
    final roleColor =
        isAdmin ? const Color(0xFF9B59B6) : const Color(0xFF3498DB);
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
            child: Icon(
                isAdmin
                    ? Icons.manage_accounts_outlined
                    : Icons.person_outline,
                size: 20,
                color: roleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A))),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF11BD51).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF11BD51),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(role,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: roleColor)),
          ),
          if (!isCurrentUser) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _deleteUser(docId, name),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 15, color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradeBadge(String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _gradeColor(grade),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(grade,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: const Color(0xFFCCCCCC)),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFCCCCCC))),
          ],
        ),
      ),
    );
  }
}