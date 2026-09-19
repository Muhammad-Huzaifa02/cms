import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/account_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/feedback_text.dart';

/// Lets the signed-in user edit their OWN name, phone number, and email,
/// and optionally change their password. Email uses a verify-then-sync
/// flow (see AuthService.requestEmailChange/confirmEmailChangeIfVerified)
/// since Firebase only actually swaps the login email once the person
/// clicks a verification link sent to the new address.
class EditProfileScreen extends StatefulWidget {
  final AppUser currentUser;
  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  final _biometricService = BiometricService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailDisplayCtrl;
  final _newPasswordCtrl = TextEditingController();

  bool _savingDetails = false;
  bool _savingPassword = false;
  bool _syncingEmail = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _obscurePassword = true;
  String? _detailsError;
  String? _detailsSuccess;
  String? _passwordError;
  String? _passwordSuccess;
  String? _emailStatus;
  bool _emailStatusIsError = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.name);
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone ?? '');
    _emailDisplayCtrl = TextEditingController(text: widget.currentUser.email ?? '');
    _loadBiometricStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailDisplayCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isLockEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  bool get _phoneLooksValid => _auth.normalizePhone(_phoneCtrl.text).length >= 7;

  Future<void> _saveDetails() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        _detailsError = 'Name is required.';
        _detailsSuccess = null;
      });
      return;
    }
    if (!_phoneLooksValid) {
      setState(() {
        _detailsError = 'Enter a valid phone number.';
        _detailsSuccess = null;
      });
      return;
    }
    setState(() {
      _savingDetails = true;
      _detailsError = null;
      _detailsSuccess = null;
    });
    try {
      await _auth.updateOwnProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        previousPhone: widget.currentUser.phone ?? '',
      );
      if (!mounted) return;
      setState(() => _detailsSuccess = 'Details saved.');
    } catch (e) {
      setState(() => _detailsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _showChangeEmailDialog() async {
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? dialogError;
    bool sending = false;

    final requested = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "We'll send a verification link to the new address. Your login email only actually changes once you click that link.",
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'New email address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: sending ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: sending
                  ? null
                  : () async {
                      setDialogState(() => sending = true);
                      try {
                        await _auth.requestEmailChange(
                          newEmail: newEmailCtrl.text.trim(),
                          currentPassword: passwordCtrl.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        setDialogState(() {
                          dialogError = e.toString().replaceFirst('Exception: ', '');
                          sending = false;
                        });
                      }
                    },
              child: sending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send verification link'),
            ),
          ],
        ),
      ),
    );

    if (requested == true && mounted) {
      setState(() {
        _emailStatus = "Verification link sent to ${newEmailCtrl.text.trim()}. Click it, then tap \"Sync now\" below.";
        _emailStatusIsError = false;
      });
    }
  }

  Future<void> _syncEmailIfVerified() async {
    setState(() {
      _syncingEmail = true;
      _emailStatus = null;
    });
    try {
      final synced = await _auth.confirmEmailChangeIfVerified(phone: _phoneCtrl.text.trim());
      if (!mounted) return;
      if (synced) {
        final freshEmail = _auth.currentUser?.email ?? '';
        setState(() {
          _emailDisplayCtrl.text = freshEmail;
          _emailStatus = 'Email updated.';
          _emailStatusIsError = false;
        });
      } else {
        setState(() {
          _emailStatus = "Not verified yet — click the link in your new inbox first.";
          _emailStatusIsError = true;
        });
      }
    } catch (e) {
      setState(() {
        _emailStatus = e.toString().replaceFirst('Exception: ', '');
        _emailStatusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _syncingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters.';
        _passwordSuccess = null;
      });
      return;
    }
    setState(() {
      _savingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });
    try {
      await _auth.changeOwnPassword(_newPasswordCtrl.text);
      if (!mounted) return;
      _newPasswordCtrl.clear();
      setState(() => _passwordSuccess = 'Password changed.');
    } catch (e) {
      setState(() => _passwordError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (enabled) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Confirm your fingerprint/Face ID to enable app lock',
      );
      if (authenticated) {
        await _biometricService.setLockEnabled(true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("App lock enabled — you'll need to confirm biometrics each time you open CMS.")),
          );
        }
      }
    } else {
      await _biometricService.setLockEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App lock disabled.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SectionCard(
              title: 'Details',
              children: [
                AccountField(label: 'Full Name', controller: _nameCtrl),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                if (_detailsError != null) FeedbackText(_detailsError!, isError: true),
                if (_detailsSuccess != null) FeedbackText(_detailsSuccess!),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Save Details',
                  loading: _savingDetails,
                  onPressed: _saveDetails,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Email Address',
              children: [
                AccountField(label: 'Email (Login)', controller: _emailDisplayCtrl, readOnly: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Changing your email requires verifying the new address first.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
                      ),
                    ),
                    TextButton(
                      onPressed: _showChangeEmailDialog,
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text('Change'),
                    ),
                  ],
                ),
                if (_emailStatus != null) FeedbackText(_emailStatus!, isError: _emailStatusIsError),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _syncingEmail ? null : _syncEmailIfVerified,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                    child: _syncingEmail
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Already verified a new email? Sync now', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_biometricAvailable) ...[
              SectionCard(
                title: 'Biometric Login',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _biometricEnabled ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _biometricEnabled ? AppColors.brand : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _biometricEnabled
                                  ? "Fingerprint/Face ID required to open the app"
                                  : 'Require fingerprint or Face ID to open CMS',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _biometricEnabled,
                        activeThumbColor: AppColors.brand,
                        onChanged: _toggleBiometrics,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SectionCard(
              title: 'Change Password',
              children: [
                AccountField(
                  label: 'New Password',
                  controller: _newPasswordCtrl,
                  obscureText: _obscurePassword,
                  helperText: 'Minimum 6 characters.',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: AppColors.muted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (_passwordError != null) FeedbackText(_passwordError!, isError: true),
                if (_passwordSuccess != null) FeedbackText(_passwordSuccess!),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Change Password',
                  loading: _savingPassword,
                  onPressed: _changePassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
