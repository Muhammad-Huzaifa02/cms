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
import 'package:cms/core/widgets/inactivity_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cms/core/utils/device_integrity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check with Play Integrity (Android) and Debug provider (development)
  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
        appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('App Check initialization: $e');
    }
  }

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
      builder: (context, child) {
        // Normalizes font scaling to standard normal size (1.0) across all devices.
        // If a user has enabled extra small or extra large font scaling in their
        // phone OS accessibility settings, the app automatically normalizes to the
        // standard, crisp, professional banking font size so UI layouts remain
        // perfectly proportioned without overflows or text distortions.
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _AuthGate(authService: authService ?? AuthService()),
    );
  }
}

/// Routes to Login or Dashboard based on Firebase Auth state, and loads
/// the matching `users/{uid}` document (role/permissions) before landing
/// on the Dashboard.
class _AuthGate extends StatefulWidget {
  final AuthService authService;
  const _AuthGate({required this.authService});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<bool> _integrityCheck = DeviceIntegrityService.instance.isDeviceCompromised();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _integrityCheck,
      builder: (context, integritySnap) {
        if (integritySnap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brand)));
        }

        // If device is rooted or jailbroken, block execution to protect customer financial data
        if (integritySnap.data == true) {
          return Scaffold(
            backgroundColor: AppColors.brandDeep,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_outlined, color: AppColors.danger, size: 54),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Security Alert',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'For security compliance, this banking customer management application cannot run on a rooted or modified device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: widget.authService.authStateChanges,
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
            if (firebaseUser == null) return LoginScreen(authService: widget.authService);

            return StreamBuilder<AppUser?>(
              stream: widget.authService.appUserStream(firebaseUser.uid),
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
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.authService.signOut());
                  }
                  return LoginScreen(authService: widget.authService);
                }
                return _LockGate(currentUser: appUser, authService: widget.authService);
              },
            );
          },
        );
      },
    );
  }
}

/// Wraps Dashboard behind BiometricLockScreen when the user has App
/// Lock enabled in My Account or when a session times out due to inactivity.
class _LockGate extends StatefulWidget {
  final AppUser currentUser;
  final AuthService authService;
  const _LockGate({required this.currentUser, required this.authService});

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  final _biometricService = BiometricService();
  bool _lockEnabled = false;
  bool _loadingLock = true;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    final enabled = await _biometricService.isLockEnabled(widget.currentUser.uid);
    if (mounted) {
      setState(() {
        _lockEnabled = enabled;
        _loadingLock = false;
      });
    }
  }

  void _handleInactivityTimeout() {
    if (!mounted || _timedOut) return;
    setState(() => _timedOut = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session locked due to 5 minutes of inactivity to protect customer data.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _handleUnlocked() {
    if (mounted && _timedOut) {
      setState(() => _timedOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLock) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    final dashboard = DashboardScreen(currentUser: widget.currentUser);

    // If biometric lock is enabled OR the session timed out from 5 min of inactivity:
    if (_lockEnabled || _timedOut) {
      return BiometricLockScreen(
        uid: widget.currentUser.uid,
        isTimedOut: _timedOut,
        onSignOut: widget.authService.signOut,
        onUnlocked: _handleUnlocked,
        child: InactivityWatcher(
          timeoutDuration: const Duration(minutes: 5),
          onTimeout: _handleInactivityTimeout,
          child: dashboard,
        ),
      );
    }

    return InactivityWatcher(
      timeoutDuration: const Duration(minutes: 5),
      onTimeout: _handleInactivityTimeout,
      child: dashboard,
    );
  }
}
