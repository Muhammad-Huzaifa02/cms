import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

/// Name, email, phone, and password are all mandatory here too — matches
/// CreateAdminScreen and AuthService.createStaffAccount's requirement that
/// every account have a real email (Firebase Auth identity) AND a real
/// phone (registered via phoneIndex), so staff can sign in with either.
class AddStaffScreen extends StatefulWidget {
  final AppUser currentUser;
  const AddStaffScreen({super.key, required this.currentUser});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _view = true, _add = false, _edit = false, _delete = false;
  bool _saving = false;
  String? _error;

  bool get _emailLooksValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim());
  bool get _phoneLooksValid => _auth.normalizePhone(_phoneCtrl.text).length >= 7;

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
      await _auth.createStaffAccount(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        permissions: Permissions(view: _view, add: _add, edit: _edit, delete: _delete),
        createdByUid: widget.currentUser.uid,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add staff account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name *')),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address *', prefixIcon: Icon(Icons.email_outlined, size: 19)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number *', prefixIcon: Icon(Icons.phone_outlined, size: 19)),
          ),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary password *')),
          const SizedBox(height: 6),
          const Text('* All fields required — staff can login with either their email or phone number.',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
          const SizedBox(height: 18),
          const Text('PERMISSIONS', style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w600)),
          SwitchListTile(title: const Text('View customers'), value: _view, onChanged: (v) => setState(() => _view = v)),
          SwitchListTile(title: const Text('Add customers'), value: _add, onChanged: (v) => setState(() => _add = v)),
          SwitchListTile(title: const Text('Edit customers'), value: _edit, onChanged: (v) => setState(() => _edit = v)),
          SwitchListTile(title: const Text('Delete customers'), value: _delete, onChanged: (v) => setState(() => _delete = v)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}
