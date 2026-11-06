import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/staff_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import 'add_staff_screen.dart';
import 'staff_profile_screen.dart';

/// Modernized Staff Management Screen for Administrators.
/// Provides real-time search, status filtering, role badges, live permission
/// toggling, and dedicated staff profile inspection.
class StaffManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  const StaffManagementScreen({super.key, required this.currentUser});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _service = StaffService();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Deactivated'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePermission(AppUser staff, String perm, bool value) async {
    final updated = staff.permissions.copyWith(
      view: perm == 'view' ? value : null,
      add: perm == 'add' ? value : null,
      edit: perm == 'edit' ? value : null,
      delete: perm == 'delete' ? value : null,
    );
    try {
      await _service.updatePermissions(
        staffUid: staff.uid,
        permissions: updated,
        actor: widget.currentUser,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permission: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(AppUser staff, bool active) async {
    try {
      await _service.setActive(
        staffUid: staff.uid,
        active: active,
        actor: widget.currentUser,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Admin access only.', style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _service.staffList(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final allStaff = snap.data!;

          // Filter by status and search query
          final filteredStaff = allStaff.where((s) {
            if (_statusFilter == 'Active' && !s.active) return false;
            if (_statusFilter == 'Deactivated' && s.active) return false;
            if (_query.isNotEmpty) {
              final q = _query.toLowerCase();
              final matchesName = s.name.toLowerCase().contains(q);
              final matchesEmail = (s.email ?? '').toLowerCase().contains(q);
              final matchesPhone = (s.phone ?? '').contains(q);
              return matchesName || matchesEmail || matchesPhone;
            }
            return true;
          }).toList();

          final activeCount = allStaff.where((s) => s.active).length;
          final deactivatedCount = allStaff.length - activeCount;

          return Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name, email, or phone…',
                    hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.brand),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              // Status Filter Chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusChip('All', allStaff.length),
                      const SizedBox(width: 8),
                      _statusChip('Active', activeCount),
                      const SizedBox(width: 8),
                      _statusChip('Deactivated', deactivatedCount),
                    ],
                  ),
                ),
              ),

              // Staff List
              Expanded(
                child: filteredStaff.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_outlined, size: 54, color: AppColors.muted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              _query.isEmpty ? 'No staff accounts found.' : 'No matching staff members.',
                              style: const TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: filteredStaff.length,
                        itemBuilder: (context, i) {
                          final s = filteredStaff[i];
                          final initials = s.name.trim().isEmpty
                              ? '?'
                              : s.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFE4ECE8), width: 1.1),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => push3D(
                                context,
                                StaffProfileScreen(staff: s, currentUser: widget.currentUser),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Avatar, Name, Role & Status Switch
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: _getStaffGradient(s.name),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15.5,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: s.active
                                                          ? AppColors.successSoft
                                                          : AppColors.danger.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: s.active ? AppColors.success : AppColors.danger,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          s.active ? 'ACTIVE' : 'DEACTIVATED',
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: s.active ? AppColors.success : AppColors.danger,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    s.permissions.roleCategory.label,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: s.active,
                                          onChanged: (v) => _toggleActive(s, v),
                                        ),
                                      ],
                                    ),

                                    // Secondary Info: Phone & Email
                                    if (s.email != null || s.phone != null) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        children: [
                                          if (s.phone != null && s.phone!.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 13, color: AppColors.muted),
                                                const SizedBox(width: 4),
                                                Text(s.phone!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                              ],
                                            ),
                                          if (s.email != null && s.email!.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.email_outlined, size: 13, color: AppColors.muted),
                                                const SizedBox(width: 4),
                                                Text(s.email!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 10),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 8),

                                    // Permission Chips Row
                                    Row(
                                      children: [
                                        const Text(
                                          'PERMISSIONS:',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.muted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            _permChip('View', s.permissions.view, (v) => _togglePermission(s, 'view', v)),
                                            _permChip('Add', s.permissions.add, (v) => _togglePermission(s, 'add', v)),
                                            _permChip('Edit', s.permissions.edit, (v) => _togglePermission(s, 'edit', v)),
                                            _permChip('Delete', s.permissions.delete, (v) => _togglePermission(s, 'delete', v)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () => push3D(context, AddStaffScreen(currentUser: widget.currentUser)),
        icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
        label: const Text('Add Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statusChip(String label, int count) {
    final selected = _statusFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = label),
      selectedColor: AppColors.brandSoft,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.brandDeep : AppColors.muted,
      ),
    );
  }

  Widget _permChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.brandSoft,
      checkmarkColor: AppColors.brand,
      labelStyle: TextStyle(color: value ? AppColors.brand : AppColors.muted),
      backgroundColor: const Color(0xFFF1F4F3),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
