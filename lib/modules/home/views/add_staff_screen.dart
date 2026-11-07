import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

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
  StaffRoleCategory _selectedRole = StaffRoleCategory.viewer;
  bool _view = true, _add = false, _edit = false, _delete = false;
  bool _saving = false;
  String? _error;

  bool get _emailLooksValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim());

  Permissions get _permissions => Permissions(view: _view, add: _add, edit: _edit, delete: _delete);

  void _updatePermissions({bool? view, bool? add, bool? edit, bool? delete}) {
    setState(() {
      if (view != null) _view = view;
      if (add != null) _add = add;
      if (edit != null) _edit = edit;
      if (delete != null) _delete = delete;
      _selectedRole = _permissions.roleCategory;
    });
  }

  void _selectRole(StaffRoleCategory? role) {
    if (role == null) return;
    setState(() {
      _selectedRole = role;
      if (role != StaffRoleCategory.custom) {
        final permissions = role.permissions;
        _view = permissions.view;
        _add = permissions.add;
        _edit = permissions.edit;
        _delete = permissions.delete;
      }
    });
  }

  Future<void> _create() async {
    final missing = <String>[];
    if (_nameCtrl.text.trim().isEmpty) missing.add('name');
    if (_emailCtrl.text.trim().isEmpty) {
      missing.add('email');
    } else if (!_emailLooksValid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    // Strict Pakistani mobile format (11 digits, starts with "03") — same
    // rule as Customer phone numbers, kept in one place via Validators so
    // Staff and Customer forms can't silently drift apart.
    final phoneError = Validators.phone(_phoneCtrl.text);
    if (_phoneCtrl.text.trim().isEmpty) {
      missing.add('phone number');
    } else if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    final passError = Validators.password(_passwordCtrl.text);
    if (_passwordCtrl.text.isEmpty) {
      missing.add('temporary password');
    } else if (passError != null) {
      setState(() => _error = passError);
      return;
    }

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
        permissions: _permissions,
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            decoration: const InputDecoration(labelText: 'Phone number *', hintText: '03001234567', prefixIcon: Icon(Icons.phone_outlined, size: 19)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Temporary password *',
              hintText: '8+ chars (upper, lower, number, symbol)',
            ),
          ),
          const SizedBox(height: 6),
          const Text('* All fields required — staff can login with either their email or phone number.',
              style: TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 18),
          const Text('Staff role', style: TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StaffRoleCategory>(
                value: _selectedRole,
                isExpanded: true,
                items: StaffRoleCategory.values
                    .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
                    .toList(),
                onChanged: _selectRole,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(_selectedRole.description, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 6),
          const Text('Admin access is managed separately and cannot be assigned here.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 14),
          const Text('Permissions', style: TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w700)),
          SwitchListTile(title: const Text('View customers'), value: _view, onChanged: (v) => _updatePermissions(view: v)),
          SwitchListTile(title: const Text('Add customers'), value: _add, onChanged: (v) => _updatePermissions(add: v)),
          SwitchListTile(title: const Text('Edit customers'), value: _edit, onChanged: (v) => _updatePermissions(edit: v)),
          SwitchListTile(title: const Text('Delete customers'), value: _delete, onChanged: (v) => _updatePermissions(delete: v)),
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
          ])),
        ],
      ),
    );
  }
}
