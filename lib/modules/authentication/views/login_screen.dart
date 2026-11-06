import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/utils/login_rate_limiter.dart';
import '../../../core/widgets/fade_in_slide.dart';
import 'create_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth = widget.authService ?? AuthService();
  late final Future<bool> _adminExistsFuture = _auth.adminAlreadyExists();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _rateLimiter = LoginRateLimiter.instance;
  final _biometricService = BiometricService();
  Timer? _countdownTimer;
  int _lockoutSecondsLeft = 0;
  bool _loading = false;
  bool _loggingInWithBiometric = false;
  bool _obscurePassword = true;
  String? _error;
  Map<String, String>? _savedBiometricAccount;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkInitialLockout();
    _loadBiometricLogin();
  }

  Future<void> _loadBiometricLogin() async {
    final available = await _biometricService.isBiometricAvailable();
    final account = await _biometricService.getSavedBiometricCredentials();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _savedBiometricAccount = account;
        if (account != null && _identifierCtrl.text.isEmpty) {
          _identifierCtrl.text = account['email'] ?? '';
        }
      });
    }
  }

  void _checkInitialLockout() {
    if (_rateLimiter.isLockedOut) {
      _startLockoutTimer(_rateLimiter.remainingLockoutSeconds);
    }
  }

  void _startLockoutTimer(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutSecondsLeft = seconds;
      _error = 'Too many failed login attempts. Please wait $_lockoutSecondsLeft seconds.';
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _rateLimiter.remainingLockoutSeconds;
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _lockoutSecondsLeft = 0;
          _error = null;
        });
      } else {
        setState(() {
          _lockoutSecondsLeft = remaining;
          _error = 'Too many failed login attempts. Please wait $_lockoutSecondsLeft seconds.';
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_rateLimiter.isLockedOut) {
      _startLockoutTimer(_rateLimiter.remainingLockoutSeconds);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      AuthSessionState.markFreshLogin();
      final user = await _auth.signIn(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      _rateLimiter.recordSuccessfulLogin();

      // Remember credentials in secure hardware vault if biometric lock is enabled
      final lockEnabled = await _biometricService.isLockEnabled(user.uid);
      if (lockEnabled) {
        await _biometricService.saveBiometricCredentials(
          uid: user.uid,
          email: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: user.name,
        );
      }
    } catch (e) {
      final lockoutTime = _rateLimiter.recordFailedAttempt();
      if (lockoutTime > 0) {
        _startLockoutTimer(lockoutTime);
      } else {
        final remainingTries = LoginRateLimiter.maxAllowedAttempts - _rateLimiter.failedAttempts;
        final baseMsg = e.toString().replaceFirst('Exception: ', '');
        final warningMsg = remainingTries <= 2
            ? '$baseMsg ($remainingTries attempts remaining before temporary lockout).'
            : baseMsg;
        setState(() => _error = warningMsg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_savedBiometricAccount == null || _loggingInWithBiometric) return;
    final email = _savedBiometricAccount!['email']!;
    final password = _savedBiometricAccount!['password']!;
    final name = _savedBiometricAccount!['name']!;

    setState(() {
      _loggingInWithBiometric = true;
      _error = null;
    });

    final result = await _biometricService.authenticate(
      reason: 'Authenticate with fingerprint to log in as $name',
    );

    if (!mounted) return;

    if (result == BiometricResult.success) {
      try {
        AuthSessionState.markFreshLogin();
        await _auth.signIn(identifier: email, password: password);
        _rateLimiter.recordSuccessfulLogin();
      } catch (e) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } else if (result != BiometricResult.cancelled) {
      setState(() => _error = result.message);
    }

    if (mounted) setState(() => _loggingInWithBiometric = false);
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(
      text: _identifierCtrl.text.contains('@') ? _identifierCtrl.text.trim() : '',
    );
    String? dialogError;
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your account's email — we'll send a link to reset your password.",
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email address'),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (!email.contains('@')) {
                  setDialogState(() => dialogError = 'Enter a valid email address.');
                  return;
                }
                try {
                  await _auth.sendPasswordReset(email);
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  setDialogState(() => dialogError = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check your email for a link to reset your password.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: FadeInSlide(
                duration: const Duration(milliseconds: 300),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInSlide(
                      delay: const Duration(milliseconds: 50),
                      offset: const Offset(0, -20),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 10))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/icon/app_logo.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const FadeInSlide(
                      delay: Duration(milliseconds: 100),
                      child: Text('Customer Management System', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 3),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 150),
                      child: Text('Branch Customer Portal', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5)),
                    ),
                    const SizedBox(height: 26),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) {
                        return Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0018)
                              ..rotateX((1 - t) * 0.45)
                              ..rotateY((1 - t) * -0.1)
                              // ignore: deprecated_member_use
                              ..scale(0.8 + (0.2 * t), 0.8 + (0.2 * t), 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.brandDeep)),
                            const SizedBox(height: 4),
                            const Text('Enter your registered email address', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _identifierCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email address',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 19,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, size: 19),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _showForgotPasswordDialog,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                                child: const Text('Forgot password?', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 4),
                              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_loading || _lockoutSecondsLeft > 0) ? null : _signIn,
                                child: _loading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_lockoutSecondsLeft > 0 ? 'Locked ($_lockoutSecondsLeft s)' : 'Login'),
                              ),
                            ),
                            if (_savedBiometricAccount != null && _biometricAvailable) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: AppColors.border, height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: AppColors.muted.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: AppColors.border, height: 1)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brandDeep,
                                    side: const BorderSide(color: AppColors.brand, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: _loggingInWithBiometric
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                                        )
                                      : const Icon(Icons.fingerprint_rounded, size: 24, color: AppColors.brand),
                                  label: Text(
                                    _loggingInWithBiometric
                                        ? 'Verifying…'
                                        : 'Log in with Biometrics',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: (_loading || _loggingInWithBiometric || _lockoutSecondsLeft > 0)
                                      ? null
                                      : _loginWithBiometrics,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 18),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 180),
                      child: FutureBuilder<bool>(
                        future: _adminExistsFuture,
                        builder: (context, snap) {
                          // While loading, or once an Admin exists, show nothing —
                          // this link is only for the very first setup.
                          if (snap.connectionState != ConnectionState.done || snap.data == true) {
                            return const SizedBox.shrink();
                          }
                          return TextButton(
                            onPressed: () => push3D(context, CreateAdminScreen(authService: _auth)),
                            child: Text(
                              'First time? Create the Admin account',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
