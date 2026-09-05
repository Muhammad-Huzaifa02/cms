import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityAction {
  customerCreated,
  customerUpdated,
  customerDeleted,
  staffCreated,
  staffPermissionsChanged,
  staffRemoved,
  export,
}

extension ActivityActionX on ActivityAction {
  String get wire => switch (this) {
        ActivityAction.customerCreated => 'customer_created',
        ActivityAction.customerUpdated => 'customer_updated',
        ActivityAction.customerDeleted => 'customer_deleted',
        ActivityAction.staffCreated => 'staff_created',
        ActivityAction.staffPermissionsChanged => 'staff_permissions_changed',
        ActivityAction.staffRemoved => 'staff_removed',
        ActivityAction.export => 'export',
      };

  String get label => switch (this) {
        ActivityAction.customerCreated => 'added customer',
        ActivityAction.customerUpdated => 'updated customer',
        ActivityAction.customerDeleted => 'deleted customer',
        ActivityAction.staffCreated => 'created staff account',
        ActivityAction.staffPermissionsChanged => 'changed permissions for',
        ActivityAction.staffRemoved => 'removed staff account',
        ActivityAction.export => 'exported customer list',
      };
}

class ActivityLogEntry {
  final String logId;
  final ActivityAction action;
  final String targetId;
  final String performedBy;
  final String performedByName;
  final DateTime? timestamp;
  final String? details;

  const ActivityLogEntry({
    required this.logId,
    required this.action,
    required this.targetId,
    required this.performedBy,
    required this.performedByName,
    this.timestamp,
    this.details,
  });

  factory ActivityLogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final wire = data['action'] as String? ?? '';
    final action = ActivityAction.values.firstWhere(
      (a) => a.wire == wire,
      orElse: () => ActivityAction.customerUpdated,
    );
    return ActivityLogEntry(
      logId: doc.id,
      action: action,
      targetId: data['targetId'] ?? '',
      performedBy: data['performedBy'] ?? '',
      performedByName: data['performedByName'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      details: data['details'],
    );
  }

  Map<String, dynamic> toMap() => {
        'action': action.wire,
        'targetId': targetId,
        'performedBy': performedBy,
        'performedByName': performedByName,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
      };
}
