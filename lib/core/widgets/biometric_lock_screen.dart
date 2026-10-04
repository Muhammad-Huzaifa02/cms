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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap below to continue with fingerprint',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checking ? null : _tryBiometricLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.brandDeep),
                      icon: _checking
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand))
                          : const Icon(Icons.fingerprint),
                      label: Text(_checking ? 'Checking…' : 'Login with Fingerprint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onSignOut,
                    child: Text('Use password instead', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
