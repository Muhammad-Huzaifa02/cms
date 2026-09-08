import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/biometric_service.dart';
import '../../../core/theme/app_theme.dart';

/// Lets the signed-in user edit their OWN name and phone number, and
/// optionally change their password. Email is shown read-only — it's the
/// real Firebase Auth login identity, and safely changing it needs a
/// verification flow that's out of scope here (see AuthService docs).
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
  final _newPasswordCtrl = TextEditingController();

  bool _savingDetails = false;
  bool _savingPassword = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _detailsError;
  String? _detailsSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.name);
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone ?? '');
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
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
      setState(() => _detailsError = 'Name is required.');
      return;
    }
    if (!_phoneLooksValid) {
      setState(() => _detailsError = 'Enter a valid phone number.');
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
      setState(() => _detailsSuccess = 'Saved.');
    } catch (e) {
      setState(() => _detailsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
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
      final password = await showDialog<String>(
        context: context,
        builder: (context) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Enable Biometrics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your password to enable biometric login.'),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, ctrl.text),
                style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                child: const Text('Verify'),
              ),
            ],
          );
        },
      );

      if (password == null || password.isEmpty) return;

      final authenticated = await _biometricService.authenticate(
        reason: 'Confirm your biometric to enable biometric login',
      );

      if (authenticated) {
        final email = widget.currentUser.email;
        if (email != null) {
          await _biometricService.saveCredentials(email, password);
          await _biometricService.setBiometricEnabled(true);
          if (mounted) {
            setState(() => _biometricEnabled = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric login enabled successfully.')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot enable biometric login: No email associated with this account.')),
            );
          }
        }
      }
    } else {
      await _biometricService.clearCredentials();
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login disabled.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DETAILS', style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: user.email ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'Email (login)',
                      helperText: "Email can't be changed here — contact support if needed.",
                      helperMaxLines: 2,
                    ),
                  ),
                  if (_detailsError != null) ...[
                    const SizedBox(height: 8),
                    Text(_detailsError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  if (_detailsSuccess != null) ...[
                    const SizedBox(height: 8),
                    Text(_detailsSuccess!, style: const TextStyle(color: AppColors.brand, fontSize: 12)),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingDetails ? null : _saveDetails,
                      child: _savingDetails
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_biometricAvailable) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: const Text('Biometric Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _biometricEnabled ? 'Enabled' : 'Disabled',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _biometricEnabled,
                  activeTrackColor: AppColors.brand,
                  onChanged: _toggleBiometrics,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHANGE PASSWORD', style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password (6+ characters)'),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Text(_passwordError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  if (_passwordSuccess != null) ...[
                    const SizedBox(height: 8),
                    Text(_passwordSuccess!, style: const TextStyle(color: AppColors.brand, fontSize: 12)),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      child: _savingPassword
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Change password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
