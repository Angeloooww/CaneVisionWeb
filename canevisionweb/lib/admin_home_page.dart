import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_login_page.dart';
import 'admin_home/admin_common.dart';
import 'admin_home/certificates_tab.dart';
import 'admin_home/dashboard_tab.dart';
import 'admin_home/farmers_tab.dart';
import 'admin_home/grades_tab.dart';
import 'admin_home/graders_tab.dart';
import 'admin_home/reports_tab.dart';

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // 0=Dashboard 1=Farmers 2=Graders 3=Grades 4=Certificates 5=Reports
  int _selectedTab = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<_TabItem> _tabs = [
    _TabItem(Icons.dashboard_outlined, 'Dashboard'),
    _TabItem(Icons.grass_outlined, 'Farmers'),
    _TabItem(Icons.people_outline, 'Graders'),
    _TabItem(Icons.workspace_premium_outlined, 'Grades'),
    _TabItem(Icons.verified_outlined, 'Certificates'),
    _TabItem(Icons.print_outlined, 'Reports'),
  ];

  // ── Logout ────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  Widget _buildPage() {
    switch (_selectedTab) {
      case 0:
        return DashboardTab(
            onViewFarmers: () => setState(() => _selectedTab = 1));
      case 1:
        return const FarmersTab();
      case 2:
        return const GradersTab();
      case 3:
        return const GradesTab();
      case 4:
        return const CertificatesTab();
      default:
        return const ReportsTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminName = _auth.currentUser?.displayName ?? 'Admin';
    final isWide = AdminLayout.isWide(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: Row(
        children: [
          if (isWide) _buildSidebar(adminName),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                if (!isWide) _buildMobileTabBar(),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────
  Widget _buildSidebar(String adminName) {
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
                    border:
                        Border.all(color: const Color(0xFF11BD51), width: 2),
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
          for (int i = 0; i < _tabs.length; i++)
            GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == i
                      ? const Color(0xFF11BD51).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(_tabs[i].icon,
                        size: 18,
                        color: _selectedTab == i
                            ? const Color(0xFF11BD51)
                            : const Color(0xFF888899)),
                    const SizedBox(width: 10),
                    Text(_tabs[i].label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTab == i
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedTab == i
                                ? Colors.white
                                : const Color(0xFF888899))),
                  ],
                ),
              ),
            ),

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
  Widget _buildTopBar(bool isWide) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: AdminLayout.pagePad(context)),
      child: Row(
        children: [
          Expanded(
            child: Text(_tabs[_selectedTab].label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
          ),
          if (!isWide)
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
                  mainAxisSize: MainAxisSize.min,
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
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }

  // ── Mobile Tab Bar ────────────────────────────────────────────
  Widget _buildMobileTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTab == i
                          ? const Color(0xFF11BD51).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _selectedTab == i
                          ? Border.all(
                              color: const Color(0xFF11BD51), width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabs[i].icon,
                            size: 18,
                            color: _selectedTab == i
                                ? const Color(0xFF11BD51)
                                : const Color(0xFF888888)),
                        const SizedBox(height: 3),
                        // FittedBox keeps long labels ("Certificates") on one line
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_tabs[i].label,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _selectedTab == i
                                      ? const Color(0xFF11BD51)
                                      : const Color(0xFF888888),
                                  fontWeight: _selectedTab == i
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}