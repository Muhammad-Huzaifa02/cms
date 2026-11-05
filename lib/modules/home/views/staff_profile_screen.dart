import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/staff_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/account_field.dart';

class StaffProfileScreen extends StatefulWidget {
  final AppUser staff;
  final AppUser currentUser;

  const StaffProfileScreen({
    super.key,
    required this.staff,
    required this.currentUser,
  });

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _service = StaffService();
  late AppUser _staff;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _staff = widget.staff;
  }

  Future<void> _togglePermission(String perm, bool value) async {
    setState(() => _updating = true);
    final updated = _staff.permissions.copyWith(
      view: perm == 'view' ? value : null,
      add: perm == 'add' ? value : null,
      edit: perm == 'edit' ? value : null,
      delete: perm == 'delete' ? value : null,
    );
    try {
      await _service.updatePermissions(
        staffUid: _staff.uid,
        permissions: updated,
        actor: widget.currentUser,
      );
      setState(() {
        _staff = AppUser(
          uid: _staff.uid,
          name: _staff.name,
          email: _staff.email,
          phone: _staff.phone,
          isAdmin: _staff.isAdmin,
          permissions: updated,
          active: _staff.active,
          createdBy: _staff.createdBy,
          createdAt: _staff.createdAt,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _toggleActive(bool active) async {
    setState(() => _updating = true);
    try {
      await _service.setActive(
        staffUid: _staff.uid,
        active: active,
        actor: widget.currentUser,
      );
      setState(() {
        _staff = AppUser(
          uid: _staff.uid,
          name: _staff.name,
          email: _staff.email,
          phone: _staff.phone,
          isAdmin: _staff.isAdmin,
          permissions: _staff.permissions,
          active: active,
          createdBy: _staff.createdBy,
          createdAt: _staff.createdAt,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _staff.name.trim().isEmpty
        ? '?'
        : _staff.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Staff Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.brand,
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _staff.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _staff.active ? AppColors.success : AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _staff.active ? 'Active Account' : 'Deactivated',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _staff.active ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _staff.active,
                    onChanged: _updating ? null : _toggleActive,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact details
          SectionCard(
            title: 'Contact Information',
            children: [
              AccountField(
                label: 'Email Address',
                controller: TextEditingController(text: _staff.email ?? 'Not set'),
                readOnly: true,
              ),
              const SizedBox(height: 14),
              AccountField(
                label: 'Phone Number',
                controller: TextEditingController(text: _staff.phone ?? 'Not set'),
                readOnly: true,
              ),
              if (_staff.createdAt != null) ...[
                const SizedBox(height: 14),
                AccountField(
                  label: 'Account Created',
                  controller: TextEditingController(
                    text: '${_staff.createdAt!.day}/${_staff.createdAt!.month}/${_staff.createdAt!.year}',
                  ),
                  readOnly: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Role & Permissions
          SectionCard(
            title: 'Permissions & Access',
            children: [
              Text(
                'Role: ${_staff.permissions.roleCategory.label}',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.brandDeep),
              ),
              const SizedBox(height: 4),
              Text(
                _staff.permissions.roleCategory.description,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _permChip('View Customers', _staff.permissions.view, (v) => _togglePermission('view', v)),
                  _permChip('Add Customers', _staff.permissions.add, (v) => _togglePermission('add', v)),
                  _permChip('Edit Customers', _staff.permissions.edit, (v) => _togglePermission('edit', v)),
                  _permChip('Delete Customers', _staff.permissions.delete, (v) => _togglePermission('delete', v)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _permChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      selected: value,
      onSelected: _updating ? null : onChanged,
      selectedColor: const Color(0xFFE3F0EC),
      checkmarkColor: AppColors.brand,
      labelStyle: TextStyle(color: value ? AppColors.brand : AppColors.muted),
      backgroundColor: const Color(0xFFEEEEEE),
    );
  }
}
