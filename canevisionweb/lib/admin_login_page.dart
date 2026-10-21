import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_signup_page.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const Color _green = Color(0xFF11BD51);
  static const Color _greenDark = Color(0xFF0B7A36);
  static const Color _panelGreen = Color(0xFF86DFA9);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN LOGIC ───────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }
    if (!_agreedToTerms) {
      _showMessage('Please agree to the Terms & Conditions to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        _showMessage('Account not found. Please sign up first.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final role = (doc.data()?['role'] ?? '').toString();

      if (role != 'Admin') {
        await _auth.signOut();
        _showMessage('This account is not an Admin account.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const AdminHomePage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials. Please try again.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }
      _showMessage(message);
    } catch (e) {
      _showMessage('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email above first, then tap "Forgot password".');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage('Password reset link sent to $email.', isError: false);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.code == 'invalid-email'
          ? 'Please enter a valid email address.'
          : 'Could not send the reset email. Please try again.');
    } catch (_) {
      _showMessage('Could not send the reset email. Please try again.');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Terms & Conditions dialog ─────────────────────────────────
  void _showTerms() {
    const sections = <List<String>>[
      [
        '1. Authorized use',
        'The CaneVision admin dashboard is for authorized administrators only. '
            'You may use it solely to manage farmers, graders, grading records '
            'and certificates for CaneVision.'
      ],
      [
        '2. Account security',
        'You are responsible for keeping your login credentials confidential '
            'and for all activity under your account. Do not share your password. '
            'Report any suspected unauthorized access immediately.'
      ],
      [
        '3. Data privacy and confidentiality',
        'Farmer, grader and grading information you can see is confidential. '
            'Do not copy, disclose or use it outside your official duties, and '
            'handle exported reports and certificates with care.'
      ],
      [
        '4. Accuracy of records',
        'Approvals, removals and other changes you make affect real records. '
            'Take care that the information you manage is accurate and current.'
      ],
      [
        '5. Monitoring',
        'Activity in the system may be logged for security and audit purposes.'
      ],
      [
        '6. Changes and termination',
        'CaneVision may update these terms or suspend access at any time. '
            'Continued use after changes means you accept the updated terms.'
      ],
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Terms & Conditions',
                          style: TextStyle(
                              fontSize: 18,
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
                const Text('Please read before signing in.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in sections) ...[
                          Text(s[0],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 4),
                          Text(s[1],
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Color(0xFF555555))),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close',
                          style: TextStyle(color: Color(0xFF888888))),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _agreedToTerms = true);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('I Agree'),
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

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showPanel = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Left: brand + form ──────────────────────────────
          Expanded(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    child: _buildBrand(),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildForm(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right: themed illustration panel ────────────────
          if (showPanel) Expanded(child: _buildArtPanel()),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: _green, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.grass, color: _green),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text('CaneVision',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(width: 10),
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
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome back',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 6),
        const Text('Please enter your details',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888))),

        const SizedBox(height: 32),

        // Email
        const Text('Email address',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 20),

        // Password
        const Text('Password',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: 'Enter your password',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF888888),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        const SizedBox(height: 16),

        // Terms checkbox  +  Forgot password
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                activeColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFFAAAAAA), width: 1.2),
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('I agree to the ',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF444444))),
                    GestureDetector(
                      onTap: _showTerms,
                      child: const Text('Terms & Conditions',
                          style: TextStyle(
                              fontSize: 13,
                              color: _green,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: _green)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _handleForgotPassword,
            child: const Text('Forgot password',
                style: TextStyle(
                    fontSize: 13,
                    color: _green,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _green)),
          ),
        ),

        const SizedBox(height: 24),

        // Sign in button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _green.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Sign in',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
          ),
        ),

        const SizedBox(height: 22),

        // Sign up link
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => const AdminSignupPage(),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                ),
                child: const Text('Sign up',
                    style: TextStyle(
                        fontSize: 13,
                        color: _green,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: _green)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Right-hand illustration panel (built from shapes + icons) ──
  Widget _buildArtPanel() {
    // Faint outline icons scattered in the background (like the inspiration)
    const scattered = <_Scatter>[
      _Scatter(Icons.grass_outlined, -0.78, -0.82, 44),
      _Scatter(Icons.eco_outlined, 0.62, -0.88, 38),
      _Scatter(Icons.bar_chart_rounded, -0.35, -0.62, 40),
      _Scatter(Icons.verified_outlined, 0.86, -0.46, 42),
      _Scatter(Icons.assignment_outlined, -0.88, -0.28, 40),
      _Scatter(Icons.workspace_premium_outlined, 0.34, -0.38, 44),
      _Scatter(Icons.groups_outlined, -0.62, 0.10, 40),
      _Scatter(Icons.agriculture_outlined, 0.80, 0.14, 44),
      _Scatter(Icons.wb_sunny_outlined, -0.20, -0.95, 34),
    ];

    return Container(
      color: _panelGreen,
      child: Stack(
        children: [
          // Small x / o confetti
          Positioned.fill(child: CustomPaint(painter: _ConfettiPainter())),

          for (final s in scattered)
            Align(
              alignment: Alignment(s.x, s.y),
              child: Icon(s.icon,
                  size: s.size, color: Colors.white.withOpacity(0.45)),
            ),

          // Centerpiece: "monitor" card with a check and grade bars
          Align(
            alignment: const Alignment(0, 0.38),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 190,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _greenDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            size: 52, color: _green),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final h in const [
                              70.0, 110.0, 54.0, 90.0, 40.0
                            ])
                              Container(
                                width: 16,
                                height: h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Monitor stand
                Container(width: 26, height: 26, color: _greenDark),
                Container(
                  width: 130,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _greenDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Grade smarter. Farm better.',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('Manage farmers, graders and certificates in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: (_) => _handleLogin(),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }
}

// ── Helpers for the illustration panel ──────────────────────────
class _Scatter {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  const _Scatter(this.icon, this.x, this.y, this.size);
}

/// Tiny "x" and "o" marks scattered on the panel, like the inspiration.
class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Deterministic pseudo-random layout (no flicker on rebuild)
    int seed = 7;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (int i = 0; i < 70; i++) {
      final x = next() * size.width;
      final y = next() * size.height * 0.75;
      if (i.isEven) {
        canvas.drawCircle(Offset(x, y), 4, paint);
      } else {
        canvas.drawLine(Offset(x - 4, y - 4), Offset(x + 4, y + 4), paint);
        canvas.drawLine(Offset(x - 4, y + 4), Offset(x + 4, y - 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}