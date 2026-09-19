import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cms/firebase_options.dart';
import 'package:cms/core/theme/app_theme.dart';
import 'package:cms/data/services/auth_service.dart';
import 'package:cms/data/models/user_model.dart';
import 'package:cms/modules/authentication/views/login_screen.dart';
import 'package:cms/modules/home/views/dashboard_screen.dart';
import 'package:cms/routes/app_routes.dart';
import 'package:cms/data/services/biometric_service.dart';
import 'package:cms/core/widgets/biometric_lock_screen.dart';

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
        if (firebaseUser == null) return LoginScreen(authService: authService);

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
              return LoginScreen(authService: authService);
            }
            return _LockGate(currentUser: appUser, authService: authService);
          },
        );
      },
    );
  }
}

/// Wraps Dashboard behind BiometricLockScreen only if the user has App
/// Lock enabled in My Account — everyone else goes straight to Dashboard
/// as before. Caches the lock-enabled check in initState rather than
/// re-querying on every rebuild (appUserStream can re-emit on any profile
/// change), so a rebuild while locked can't cause a flicker back to an
/// unlocked state.
class _LockGate extends StatefulWidget {
  final AppUser currentUser;
  final AuthService authService;
  const _LockGate({required this.currentUser, required this.authService});

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  late final Future<bool> _lockEnabledFuture = BiometricService().isLockEnabled();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _lockEnabledFuture,
      builder: (context, snap) {
        final dashboard = DashboardScreen(currentUser: widget.currentUser);
        if (snap.connectionState != ConnectionState.done) {
          // Don't reveal Dashboard until we actually know whether it
          // should be locked — a brief unlocked flash would defeat the
          // point of the lock.
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brand)));
        }
        if (snap.data != true) return dashboard;
        return BiometricLockScreen(
          onSignOut: widget.authService.signOut,
          child: dashboard,
        );
      },
    );
  }
}
