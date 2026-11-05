import 'package:flutter/material.dart';
import '../../data/services/biometric_service.dart';
import '../theme/app_theme.dart';

/// Sits in front of [child] (normally the Dashboard) when the signed-in
/// user has enabled Biometric Login for their account. Firebase already
/// keeps the person signed in across app restarts — that's unrelated to
/// this widget. This adds one more check in front of that already-valid
/// session: a fingerprint/Face ID prompt, required before the session
/// is allowed through.
///
/// The check is never automatic — the user taps "Login with Fingerprint"
/// themselves. A failed or cancelled attempt just leaves them here with a
/// retry option; "Use password instead" signs out and returns to normal
/// email/phone + password login as an explicit, always-available fallback.
class BiometricLockScreen extends StatefulWidget {
  final Widget child;
  final String uid;
  final Future<void> Function() onSignOut;
  const BiometricLockScreen({super.key, required this.child, required this.uid, required this.onSignOut});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with WidgetsBindingObserver {
  final _biometrics = BiometricService();
  bool _unlocked = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Deliberately NOT auto-triggering authenticate() here — the person
    // must tap "Login with Fingerprint" themselves.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Two fixes for a real bug here:
    // 1. Ignore lifecycle changes while our OWN authenticate() call is in
    //    flight (`_checking`) — showing the Face ID/Touch ID system prompt
    //    itself flips the app to `inactive` on iOS even though the user
    //    never left. Without this guard, a successful unlock could get
    //    immediately re-locked the instant the system sheet closed.
    // 2. Only re-lock on `paused` (genuinely backgrounded), not
    //    `inactive` — `inactive` also fires for lots of harmless
    //    transient states (a system dialog, the notification shade,
    //    an incoming call banner) that aren't "the user left the app".
    if (_checking) return;
    if (state == AppLifecycleState.paused) {
      if (mounted) setState(() => _unlocked = false);
    }
  }

  Future<void> _tryBiometricLogin() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await _biometrics.authenticate(reason: 'Login with fingerprint');
    if (!mounted) return;

    if (result == BiometricResult.notEnrolled) {
      // Enrollment changed since this was enabled — per spec, force
      // normal authentication rather than leaving a dead "enabled" flag
      // that can never succeed again.
      await _biometrics.setLockEnabled(widget.uid, false);
    }

    setState(() {
      _unlocked = result == BiometricResult.success;
      _checking = false;
      _error = (result == BiometricResult.success || result == BiometricResult.cancelled)
          ? null
          : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandDeep, AppColors.brand, AppColors.brandLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield + Biometric Glowing Hub
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandDeep.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Session Locked',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Touch fingerprint sensor to unlock CMS banking portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.amber, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _checking ? null : _tryBiometricLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandDeep,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _checking
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                              )
                            : const Icon(Icons.fingerprint, size: 22),
                        label: Text(
                          _checking ? 'Verifying…' : 'Unlock with Biometrics',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: widget.onSignOut,
                      icon: Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.8), size: 16),
                      label: Text(
                        'Sign in with password instead',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
