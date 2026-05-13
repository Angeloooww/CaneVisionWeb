import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase/firebase_options.dart';
import 'admin_login_page.dart';
import 'admin_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CaneVisionAdminApp());
}

class CaneVisionAdminApp extends StatelessWidget {
  const CaneVisionAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaneVision Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF11BD51),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
              const Color(0xFF11BD51).withOpacity(0.4)),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // No user logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const AdminLoginPage();
        }

        // User is logged in — verify they are an approved Admin in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            // Doc doesn't exist — sign out
            if (!docSnap.hasData || !docSnap.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const AdminLoginPage();
            }

            final data = docSnap.data!.data() as Map<String, dynamic>;
            final role = (data['role'] ?? '').toString();

            // Not an admin — sign out
            if (role != 'Admin') {
              FirebaseAuth.instance.signOut();
              return const AdminLoginPage();
            }

            // Valid admin — go to dashboard
            return const AdminHomePage();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE8F8EF),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF11BD51),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
