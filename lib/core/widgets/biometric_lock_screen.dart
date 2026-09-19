import 'package:flutter/material.dart';
import '../../data/services/biometric_service.dart';
import '../theme/app_theme.dart';

/// Sits in front of [child] (normally the Dashboard) when the user has
/// enabled App Lock in My Account. Firebase already keeps the person
/// signed in across app restarts — that's unrelated to this widget. This
/// just adds one more check in front of an already-valid session: a
/// fingerprint/Face ID prompt every time the app is opened.
///
/// Unlike the old biometric-login flow, there is no password anywhere
/// here — a failed or cancelled check simply leaves the person on this
/// locked screen with a retry button. "Sign out instead" is offered as an
/// explicit escape hatch, not an automatic fallback.
class BiometricLockScreen extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onSignOut;
  const BiometricLockScreen({super.key, required this.child, required this.onSignOut});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with WidgetsBindingObserver {
  final _biometrics = BiometricService();
  bool _unlocked = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attemptUnlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock whenever the app is backgrounded — someone picking up an
    // already-open phone shouldn't get the Dashboard for free just
    // because the app was left running.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) setState(() => _unlocked = false);
    }
  }

  Future<void> _attemptUnlock() async {
    setState(() => _checking = true);
    final success = await _biometrics.authenticate(reason: 'Unlock CMS');
    if (mounted) {
      setState(() {
        _unlocked = success;
        _checking = false;
      });
    }
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
                  const Text('CMS is locked', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Confirm your fingerprint or Face ID to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checking ? null : _attemptUnlock,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.brandDeep),
                      child: _checking
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand))
                          : const Text('Try again'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onSignOut,
                    child: Text('Sign out instead', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
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
