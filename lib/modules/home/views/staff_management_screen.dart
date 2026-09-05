import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/staff_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import 'add_staff_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  const StaffManagementScreen({super.key, required this.currentUser});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _service = StaffService();

  Future<void> _togglePermission(AppUser staff, String perm, bool value) async {
    final updated = staff.permissions.copyWith(
      view: perm == 'view' ? value : null,
      add: perm == 'add' ? value : null,
      edit: perm == 'edit' ? value : null,
      delete: perm == 'delete' ? value : null,
    );
    await _service.updatePermissions(staffUid: staff.uid, permissions: updated, actor: widget.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access only.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Staff accounts')),
      body: StreamBuilder<List<AppUser>>(
        stream: _service.staffList(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final staff = snap.data!;
          if (staff.isEmpty) {
            return const Center(child: Text('No staff accounts yet. Tap + to add one.', style: TextStyle(color: AppColors.muted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: staff.length,
            itemBuilder: (context, i) {
              final s = staff[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.brand,
                            child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                Text(s.active ? 'Active' : 'Deactivated',
                                    style: TextStyle(fontSize: 11, color: s.active ? AppColors.brand : AppColors.danger)),
                              ],
                            ),
                          ),
                          Switch(
                            value: s.active,
                            onChanged: (v) => _service.setActive(staffUid: s.uid, active: v, actor: widget.currentUser),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _permChip('View', s.permissions.view, (v) => _togglePermission(s, 'view', v)),
                          _permChip('Add', s.permissions.add, (v) => _togglePermission(s, 'add', v)),
                          _permChip('Edit', s.permissions.edit, (v) => _togglePermission(s, 'edit', v)),
                          _permChip('Delete', s.permissions.delete, (v) => _togglePermission(s, 'delete', v)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => push3D(context, AddStaffScreen(currentUser: widget.currentUser)),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _permChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      selected: value,
      onSelected: onChanged,
      selectedColor: const Color(0xFFE3F0EC),
      checkmarkColor: AppColors.brand,
      labelStyle: TextStyle(color: value ? AppColors.brand : AppColors.muted),
      backgroundColor: const Color(0xFFEEEEEE),
    );
  }
}
