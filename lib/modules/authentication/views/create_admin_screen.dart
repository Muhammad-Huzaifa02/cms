import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_slide.dart';
import '../../home/views/dashboard_screen.dart';

/// Reachable from the login screen's "First time? Create Admin account"
/// link, or shown directly as the app's first screen when no Admin exists
/// yet. Only ever succeeds once — the second person to try this hits a
/// clear "an Admin already exists" message, enforced both here and by
/// firestore.rules (see /system/bootstrap).
///
/// Name, email, phone, and password are all mandatory — email becomes the
/// real Firebase Auth login, phone is registered as a second, independent
/// way to sign in to the same account (see AuthService's phoneIndex).
class CreateAdminScreen extends StatefulWidget {
  final AuthService authService;
  const CreateAdminScreen({super.key, required this.authService});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _emailLooksValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim());
  bool get _phoneLooksValid => widget.authService.normalizePhone(_phoneCtrl.text).length >= 7;

  Future<void> _create() async {
    final missing = <String>[];
    if (_nameCtrl.text.trim().isEmpty) missing.add('name');
    if (_emailCtrl.text.trim().isEmpty) {
      missing.add('email');
    } else if (!_emailLooksValid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      missing.add('phone number');
    } else if (!_phoneLooksValid) {
      setState(() => _error = 'Enter a valid phone number.');
      return;
    }
    if (_passwordCtrl.text.length < 6) missing.add('password (6+ characters)');

    if (missing.isNotEmpty) {
      setState(() => _error = 'Required: ${missing.join(', ')}.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final admin = await widget.authService.bootstrapFirstAdmin(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(currentUser: admin)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
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
                    // Only shown when this screen was pushed from the login
                    // link — when it's the app's very first screen (no Admin
                    // exists yet), there's nothing to go back to.
                    if (Navigator.of(context).canPop())
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 50),
                      offset: const Offset(0, -15),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/icon/app_logo.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const FadeInSlide(
                      delay: Duration(milliseconds: 100),
                      child: Text('Set up your Admin account', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: Text('One-time setup — this becomes the branch owner login', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
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
                              ..rotateY((1 - t) * 0.1)
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
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Full name *',
                                prefixIcon: Icon(Icons.person_outline, size: 19),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email address *',
                                prefixIcon: Icon(Icons.email_outlined, size: 19),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone number *',
                                prefixIcon: Icon(Icons.phone_outlined, size: 19),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Password (6+ characters) *',
                                prefixIcon: Icon(Icons.lock_outline, size: 19),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('* All fields required — you can login with either the email or the phone number afterward.',
                                  style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _create,
                                child: _saving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Create Admin account'),
                              ),
                            ),
                          ],
                        ),
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
