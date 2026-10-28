import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

/// Read-only profile details for a staff account, opened from the admin
/// staff list. Permission and active-state changes remain on that list.
class StaffDetailScreen extends StatelessWidget {
  final AppUser staff;
  const StaffDetailScreen({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    final permissions = <String, bool>{
      'View customers': staff.permissions.view,
      'Add customers': staff.permissions.add,
      'Edit customers': staff.permissions.edit,
      'Delete customers': staff.permissions.delete,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Staff details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.brand,
                child: Text(
                  staff.name.isEmpty ? '?' : staff.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(staff.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Chip(
                avatar: Icon(staff.active ? Icons.check_circle : Icons.block, size: 18,
                    color: staff.active ? AppColors.brand : AppColors.danger),
                label: Text(staff.active ? 'Active' : 'Deactivated'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(children: [
              if (staff.email?.isNotEmpty == true)
                ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(staff.email!)),
              if (staff.phone?.isNotEmpty == true)
                ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Phone'), subtitle: Text(staff.phone!)),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...permissions.entries.map((entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(entry.value ? Icons.check_circle : Icons.remove_circle_outline,
                          color: entry.value ? AppColors.brand : AppColors.muted),
                      title: Text(entry.key),
                      trailing: Text(entry.value ? 'Allowed' : 'Not allowed',
                          style: TextStyle(color: entry.value ? AppColors.brand : AppColors.muted)),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
