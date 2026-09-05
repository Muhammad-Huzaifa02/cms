import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../data/services/activity_service.dart';
import '../../../core/theme/app_theme.dart';

class ActivityLogScreen extends StatelessWidget {
  final AppUser currentUser;
  const ActivityLogScreen({super.key, required this.currentUser});

  Color _dotColor(ActivityAction a) {
    switch (a) {
      case ActivityAction.customerCreated:
      case ActivityAction.staffCreated:
        return AppColors.brand;
      case ActivityAction.customerDeleted:
      case ActivityAction.staffRemoved:
        return AppColors.danger;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!currentUser.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access only.')));
    }
    final service = ActivityService();
    return Scaffold(
      appBar: AppBar(title: const Text('Activity log')),
      body: StreamBuilder<List<ActivityLogEntry>>(
        stream: service.recent(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('No activity yet.', style: TextStyle(color: AppColors.muted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final time = e.timestamp != null ? DateFormat('MMM d, h:mm a').format(e.timestamp!) : '';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _dotColor(e.action), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                                children: [
                                  TextSpan(text: e.performedByName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' ${e.action.label} '),
                                  TextSpan(text: e.targetId, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(time, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
