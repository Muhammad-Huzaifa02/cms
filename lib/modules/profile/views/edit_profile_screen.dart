import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/account_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/feedback_text.dart';

/// Executive Banking Account & Security Center.
///
/// Allows the signed-in user to view and update their profile details (Name, Phone),
/// manage login email with a secure verify-then-sync flow, update passwords,
/// configure biometric hardware app-lock, and review session credentials.
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
    final enabled = await _biometricService.isLockEnabled(widget.currentUser.uid);
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
        _detailsError = 'Enter a valid Pakistani mobile number (e.g. 03xx...).';
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
      setState(() => _detailsSuccess = 'Personal details updated successfully.');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Login Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "A secure verification link will be sent to the new address. Your login email only updates once you tap the confirmation link.",
                style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'New email address',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                Text(dialogError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
          _emailStatus = 'Email updated successfully.';
          _emailStatusIsError = false;
        });
      } else {
        setState(() {
          _emailStatus = "Not verified yet — please open the verification email link first.";
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
      final newPass = _newPasswordCtrl.text;
      await _auth.changeOwnPassword(newPass);
      // Synchronize hardware biometric vault if user has biometric login enabled
      if (_biometricEnabled) {
        await _biometricService.saveBiometricCredentials(
          uid: widget.currentUser.uid,
          email: widget.currentUser.email ?? '',
          password: newPass,
          name: widget.currentUser.name,
        );
      }
      if (!mounted) return;
      _newPasswordCtrl.clear();
      setState(() => _passwordSuccess = 'Password updated successfully.');
    } catch (e) {
      setState(() => _passwordError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (enabled) {
      final result = await _biometricService.authenticate(
        reason: 'Confirm your fingerprint/Face ID to enable biometric login',
      );
      if (result == BiometricResult.success) {
        await _biometricService.setLockEnabled(widget.currentUser.uid, true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric app-lock enabled.')),
          );
        }
      } else if (result != BiometricResult.cancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } else {
      await _biometricService.setLockEnabled(widget.currentUser.uid, false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric app-lock disabled.')),
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out of CMS?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You will need your password or verified biometrics to log back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop();
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final initials = user.name.trim().isNotEmpty
        ? user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── HERO EXECUTIVE PROFILE CARD ──
            Card(
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: user.isAdmin
                              ? [const Color(0xFFD4AF37), AppColors.gold]
                              : [AppColors.brandLight, AppColors.brand],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? user.phone ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? AppColors.gold.withValues(alpha: 0.18)
                                      : AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: user.isAdmin ? AppColors.gold : AppColors.brand.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user.isAdmin ? Icons.shield_rounded : Icons.badge_outlined,
                                      size: 11,
                                      color: user.isAdmin ? const Color(0xFFB45309) : AppColors.brand,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.isAdmin ? 'ADMINISTRATOR' : 'BANKING STAFF',
                                      style: TextStyle(
                                        color: user.isAdmin ? const Color(0xFFB45309) : AppColors.brand,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF16A34A)),
                                    SizedBox(width: 3),
                                    Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── PERSONAL PROFILE SECTION ──
            SectionCard(
              title: 'Personal Information',
              children: [
                AccountField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.brand),
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  helperText: 'Pakistani format (11 digits, starts with 03).',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.brand),
                ),
                if (_detailsError != null) FeedbackText(_detailsError!, isError: true),
                if (_detailsSuccess != null) FeedbackText(_detailsSuccess!),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Personal Details',
                  loading: _savingDetails,
                  onPressed: _saveDetails,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── LOGIN EMAIL & VERIFICATION ──
            SectionCard(
              title: 'Login & Authentication',
              children: [
                AccountField(
                  label: 'Login Email Address',
                  controller: _emailDisplayCtrl,
                  readOnly: true,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.brand),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Changing login email requires email inbox verification link.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _showChangeEmailDialog,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandSoft,
                        foregroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Change'),
                    ),
                  ],
                ),
                if (_emailStatus != null) FeedbackText(_emailStatus!, isError: _emailStatusIsError),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _syncingEmail ? null : _syncEmailIfVerified,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: _syncingEmail
                        ? const SizedBox(height: 13, width: 13, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, size: 15, color: AppColors.brand),
                    label: const Text(
                      'Already clicked the verification link? Sync now',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── HARDWARE BIOMETRIC SECURITY ──
            if (_biometricAvailable) ...[
              SectionCard(
                title: 'Biometric Hardware Vault',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _biometricEnabled
                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                              : AppColors.muted.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 24,
                          color: _biometricEnabled ? const Color(0xFF16A34A) : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _biometricEnabled ? 'Biometric App-Lock Active' : 'App-Lock Disabled',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _biometricEnabled ? const Color(0xFF16A34A) : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _biometricEnabled
                                  ? 'Fingerprint/Face ID required on launch and after 5m inactivity.'
                                  : 'Enable fingerprint or Face ID to quickly unlock CMS portal.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
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

            // ── CHANGE PASSWORD SECTION ──
            SectionCard(
              title: 'Change Password',
              children: [
                AccountField(
                  label: 'New Password',
                  controller: _newPasswordCtrl,
                  obscureText: _obscurePassword,
                  helperText: 'Must be at least 6 characters.',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.brand),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (_passwordError != null) FeedbackText(_passwordError!, isError: true),
                if (_passwordSuccess != null) FeedbackText(_passwordSuccess!),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Update Password',
                  loading: _savingPassword,
                  onPressed: _changePassword,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── SECURE SIGN OUT ──
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _confirmSignOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.danger, size: 19),
                    SizedBox(width: 8),
                    Text(
                      'Sign out of CMS',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                'CMS v1.0.0 • Secured Banking Portal',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
