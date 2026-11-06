import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/staff_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';

/// Modernized Staff Profile Screen.
/// Provides comprehensive staff inspection, real-time role preset assignment,
/// granular permission toggling, account activation controls, and 1-tap contact copying.
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

  void _copyToClipboard(String label, String? value) {
    if (value == null || value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value.trim()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  LinearGradient _getStaffGradient(String name) {
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    final palettes = [
      [AppColors.brandDeep, AppColors.brand],
      [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
      [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      [const Color(0xFF78350F), const Color(0xFFD97706)],
    ];
    final selected = palettes[hash % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: selected,
    );
  }

  Future<void> _updatePermissions(Permissions updated) async {
    setState(() => _updating = true);
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

  Future<void> _togglePermission(String perm, bool value) async {
    final updated = _staff.permissions.copyWith(
      view: perm == 'view' ? value : null,
      add: perm == 'add' ? value : null,
      edit: perm == 'edit' ? value : null,
      delete: perm == 'delete' ? value : null,
    );
    await _updatePermissions(updated);
  }

  Future<void> _assignRolePreset(StaffRoleCategory role) async {
    if (role == StaffRoleCategory.custom) return;
    await _updatePermissions(role.permissions);
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
    final role = _staff.permissions.roleCategory;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Staff Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // ── HERO PROFILE HEADER CARD ──
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getStaffGradient(_staff.name),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
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
                              _staff.name,
                              style: const TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _staff.active
                                        ? AppColors.successSoft
                                        : AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: _staff.active
                                          ? AppColors.success.withValues(alpha: 0.4)
                                          : AppColors.danger.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _staff.active ? AppColors.success : AppColors.danger,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _staff.active ? 'ACTIVE' : 'DEACTIVATED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: _staff.active ? AppColors.success : AppColors.danger,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    role.label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  // Quick Contact Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickContactBtn(
                        icon: Icons.email_rounded,
                        label: 'Copy Email',
                        value: _staff.email,
                      ),
                      _quickContactBtn(
                        icon: Icons.phone_rounded,
                        label: 'Copy Phone',
                        value: _staff.phone,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── ACCOUNT ACCESS STATUS CARD ──
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE4ECE8), width: 1.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (_staff.active ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _staff.active ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      color: _staff.active ? AppColors.success : AppColors.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _staff.active ? 'Account Enabled' : 'Account Deactivated',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _staff.active
                              ? 'Staff member can sign in and perform operations.'
                              : 'Staff member is blocked from signing in.',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
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

          // ── CONTACT INFORMATION ──
          SectionCard(
            title: 'Contact Information',
            children: [
              _infoTile(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: _staff.email ?? 'Not set',
                onCopy: _staff.email != null ? () => _copyToClipboard('Email', _staff.email) : null,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: _staff.phone ?? 'Not set',
                onCopy: _staff.phone != null ? () => _copyToClipboard('Phone Number', _staff.phone) : null,
              ),
              if (_staff.createdAt != null) ...[
                const SizedBox(height: 10),
                _infoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Account Created',
                  value: '${_staff.createdAt!.day}/${_staff.createdAt!.month}/${_staff.createdAt!.year}',
                  onCopy: null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── ROLE & PERMISSION CONFIGURATION ──
          SectionCard(
            title: 'Permissions & Access Control',
            children: [
              // Role Preset Selector
              const Text(
                'ROLE PRESET',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StaffRoleCategory>(
                    value: role,
                    isExpanded: true,
                    isDense: true,
                    items: StaffRoleCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                      );
                    }).toList(),
                    onChanged: _updating ? null : (cat) {
                      if (cat != null) _assignRolePreset(cat);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.brandDeep, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),

              // Granular Permission Toggles
              const Text(
                'GRANULAR PERMISSIONS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _permissionRow(
                icon: Icons.visibility_outlined,
                title: 'View Customers',
                description: 'Search and inspect customer records',
                value: _staff.permissions.view,
                onChanged: (v) => _togglePermission('view', v),
              ),
              const SizedBox(height: 8),
              _permissionRow(
                icon: Icons.person_add_outlined,
                title: 'Add Customers',
                description: 'Register and onboard new customer accounts',
                value: _staff.permissions.add,
                onChanged: (v) => _togglePermission('add', v),
              ),
              const SizedBox(height: 8),
              _permissionRow(
                icon: Icons.edit_outlined,
                title: 'Edit Customers',
                description: 'Modify customer records and account details',
                value: _staff.permissions.edit,
                onChanged: (v) => _togglePermission('edit', v),
              ),
              const SizedBox(height: 8),
              _permissionRow(
                icon: Icons.delete_outline,
                title: 'Delete Customers',
                description: 'Permanently remove customer records',
                value: _staff.permissions.delete,
                isDanger: true,
                onChanged: (v) => _togglePermission('delete', v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickContactBtn({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    final available = value != null && value.trim().isNotEmpty;
    return InkWell(
      onTap: available ? () => _copyToClipboard(label, value) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: available ? AppColors.brand : AppColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: available ? AppColors.brand : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 17, color: AppColors.brand),
              tooltip: 'Copy $label',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _permissionRow({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isDanger = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? (isDanger ? AppColors.danger.withValues(alpha: 0.05) : AppColors.brandSoft.withValues(alpha: 0.4))
            : const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? (isDanger ? AppColors.danger.withValues(alpha: 0.3) : AppColors.brand.withValues(alpha: 0.25))
              : const Color(0xFFE4ECE8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? (isDanger ? AppColors.danger : AppColors.brand) : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: value ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: value
                            ? (isDanger ? AppColors.danger.withValues(alpha: 0.15) : AppColors.successSoft)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value ? 'GRANTED' : 'RESTRICTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: value ? (isDanger ? AppColors.danger : AppColors.success) : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: isDanger ? AppColors.danger : AppColors.brand,
            onChanged: _updating ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
