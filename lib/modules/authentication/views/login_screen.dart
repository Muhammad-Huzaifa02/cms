import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/fade_in_slide.dart';
import '../../home/views/dashboard_screen.dart';
import 'create_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth = widget.authService ?? AuthService();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _auth.signIn(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        Perspective3DRoute(page: DashboardScreen(currentUser: user)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeInSlide(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInSlide(
                      delay: const Duration(milliseconds: 100),
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
                      delay: Duration(milliseconds: 200),
                      child: Text('Customer Management System', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 3),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      child: Text('Meezan Bank — Branch tool', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5)),
                    ),
                    const SizedBox(height: 26),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutBack,
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
                            const Text('Use either your email or phone number', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            const SizedBox(height: 16),
                            AnimatedBuilder(
                              animation: _identifierCtrl,
                              builder: (context, _) {
                                final text = _identifierCtrl.text.trim();
                                final isEmail = text.contains('@');
                                return TextField(
                                  controller: _identifierCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Email or phone number',
                                    prefixIcon: Icon(
                                      text.isEmpty ? Icons.person_outline : (isEmail ? Icons.email_outlined : Icons.phone_outlined),
                                      size: 19,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 19)),
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
                                onPressed: _loading ? null : _signIn,
                                child: _loading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 18),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 500),
                      child: FutureBuilder<bool>(
                        future: _auth.adminAlreadyExists(),
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
    );
  }
}
