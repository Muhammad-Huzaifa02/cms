import 'package:flutter/material.dart';
import '../../data/services/biometric_service.dart';
import '../theme/app_theme.dart';

/// Sits in front of [child] (normally the Dashboard) when the signed-in
/// user has enabled Biometric Login for their account, or when the session
/// locks due to inactivity.
///
/// Automatically initiates the system fingerprint / Face ID biometric
/// prompt on appearance and when returning from background. If the prompt
/// is cancelled or encounters an error, clear feedback is displayed with
/// immediate retry options and a fallback to sign out and log in with password.
class BiometricLockScreen extends StatefulWidget {
  final Widget child;
  final String uid;
  final Future<void> Function() onSignOut;
  final VoidCallback? onUnlocked;
  final bool isTimedOut;
  final BiometricService? biometricService;

  const BiometricLockScreen({
    super.key,
    required this.child,
    required this.uid,
    required this.onSignOut,
    this.onUnlocked,
    this.isTimedOut = false,
    this.biometricService,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with WidgetsBindingObserver {
  late final _biometrics = widget.biometricService ?? BiometricService();
  bool _unlocked = false;
  bool _checking = false;
  String? _error;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Automatically trigger biometric authentication prompt when the screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_unlocked) {
        _tryBiometricLogin(autoTriggered: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BiometricLockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If an inactivity timeout occurs while the widget is mounted, re-lock immediately
    if (widget.isTimedOut && !oldWidget.isTimedOut) {
      if (mounted) {
        setState(() {
          _unlocked = false;
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryBiometricLogin(autoTriggered: true);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ignore lifecycle transitions caused by the native biometric prompt itself
    if (_checking) return;

    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      if (mounted && _unlocked) {
        setState(() => _unlocked = false);
      }
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      if (mounted && !_unlocked) {
        _tryBiometricLogin(autoTriggered: true);
      }
    }
  }

  Future<void> _tryBiometricLogin({bool autoTriggered = false}) async {
    if (_checking) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    final result = await _biometrics.authenticate(
      reason: widget.isTimedOut
          ? 'Session timed out. Touch sensor to resume banking session'
          : 'Authenticate to access your CMS banking portal',
    );

    if (!mounted) return;

    if (result == BiometricResult.success) {
      setState(() {
        _unlocked = true;
        _checking = false;
        _error = null;
      });
      widget.onUnlocked?.call();
      return;
    }

    if (result == BiometricResult.notEnrolled) {
      // Enrollment changed or absent on device — disable persistent lock flag
      await _biometrics.setLockEnabled(widget.uid, false);
    }

    setState(() {
      _checking = false;
      if (result == BiometricResult.cancelled) {
        _error = autoTriggered ? null : 'Authentication cancelled. Tap to retry.';
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    final isTimeout = widget.isTimedOut;

    return Scaffold(
      backgroundColor: const Color(0xFF011814),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF011410),
              Color(0xFF022B24),
              Color(0xFF011814),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── BANK BRANDING CHIP ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: AppColors.gold),
                        SizedBox(width: 6),
                        Text(
                          'CUSTOMER MANAGEMENT SYSTEM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── BIOMETRIC GLOWING HUB ──
                  GestureDetector(
                    onTap: _checking ? null : () => _tryBiometricLogin(autoTriggered: false),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: _checking
                              ? AppColors.gold.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.22),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_checking ? AppColors.gold : AppColors.brand).withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Center(
                            child: _checking
                                ? const SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.gold,
                                    ),
                                  )
                                : Icon(
                                    Icons.fingerprint_rounded,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    size: 54,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── TITLE & SUBTITLE ──
                  Text(
                    isTimeout ? 'Session Timed Out' : 'Session Locked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isTimeout
                          ? 'Your session was locked due to 5 minutes of inactivity to protect customer data. Touch fingerprint sensor or tap below to resume.'
                          : 'Touch fingerprint sensor or tap below to unlock CMS banking portal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // ── ERROR OR STATUS BANNER ──
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 17),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── PRIMARY AUTHENTICATE BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _checking ? null : () => _tryBiometricLogin(autoTriggered: false),
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
                        _checking ? 'Verifying Identity…' : 'Unlock with Biometrics',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── SIGN OUT / PASSWORD FALLBACK ──
                  TextButton.icon(
                    onPressed: widget.onSignOut,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.75), size: 16),
                    label: const Text(
                      'Sign in with password instead',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── SECURITY STAMP ──
                  Text(
                    'CMS Bank Shield • Biometric Hardware Protection',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
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
