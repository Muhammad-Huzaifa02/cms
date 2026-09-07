import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cms/firebase_options.dart';
import 'package:cms/core/theme/app_theme.dart';
import 'package:cms/data/services/auth_service.dart';
import 'package:cms/data/models/user_model.dart';
import 'package:cms/modules/authentication/views/login_screen.dart';
import 'package:cms/modules/authentication/views/create_admin_screen.dart';
import 'package:cms/modules/home/views/dashboard_screen.dart';
import 'package:cms/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline persistence (SRS 5.5 / Data Model §6) is on by default for
  // mobile; nothing extra to enable here for Android/iOS.
  runApp(const CmsApp());
}

class CmsApp extends StatelessWidget {
  /// Injectable so widget tests can pass an AuthService built on
  /// MockFirebaseAuth/FakeFirebaseFirestore instead of real Firebase.
  /// Defaults to a real AuthService() for normal app runs.
  final AuthService? authService;

  const CmsApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMS — Customer Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: _AuthGate(authService: authService ?? AuthService()),
    );
  }
}

/// Routes to Login or Dashboard based on Firebase Auth state, and loads
/// the matching `users/{uid}` document (role/permissions) before landing
/// on the Dashboard.
class _AuthGate extends StatelessWidget {
  final AuthService authService;
  const _AuthGate({required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icon/app_logo.png', width: 80, height: 80),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.brand),
                ],
              ),
            ),
          );
        }
        final firebaseUser = snap.data;
        if (firebaseUser == null) return _SignedOutGate(authService: authService);

        return StreamBuilder<AppUser?>(
          stream: authService.appUserStream(firebaseUser.uid),
          builder: (context, userSnap) {
            // We show a spinner while waiting for the stream's first value
            // OR if the document doesn't exist yet (appUser == null). This
            // handles the race condition where Auth creation fires before
            // the Firestore record is written.
            if (userSnap.connectionState == ConnectionState.waiting || userSnap.data == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icon/app_logo.png', width: 80, height: 80),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: AppColors.brand),
                    ],
                  ),
                ),
              );
            }

            final appUser = userSnap.data;
            if (appUser == null || !appUser.active) {
              if (appUser != null && !appUser.active) {
                // Deactivated user: sign them out AFTER the current build frame
                // to avoid side-effects during build.
                WidgetsBinding.instance.addPostFrameCallback((_) => authService.signOut());
              }
              return _SignedOutGate(authService: authService);
            }
            return DashboardScreen(currentUser: appUser);
          },
        );
      },
    );
  }
}

class _SignedOutGate extends StatelessWidget {
  final AuthService authService;
  const _SignedOutGate({required this.authService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authService.adminAlreadyExists(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icon/app_logo.png', width: 80, height: 80),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.brand),
                ],
              ),
            ),
          );
        }
        final adminExists = snap.data ?? false;
        return adminExists
            ? LoginScreen(authService: authService)
            : CreateAdminScreen(authService: authService);
      },
    );
  }
}
