import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log_model.dart';
import '../models/user_model.dart';

/// Append-only — there is intentionally no update/delete method here.
/// Security Rules also hard-block update/delete on this collection
/// (Data Model §5), so even a compromised client can't rewrite history.
class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('activityLog');

  /// Adds an audit record to a caller-owned Firestore transaction. The
  /// business write and its audit event then commit or fail together.
  void stageInTransaction(
    Transaction transaction, {
    required String logId,
    required ActivityAction action,
    required String targetId,
    required AppUser actor,
    String? details,
  }) {
    final entry = ActivityLogEntry(
      logId: logId,
      action: action,
      targetId: targetId,
      performedBy: actor.uid,
      performedByName: actor.name,
      details: details,
    );
    transaction.set(_col.doc(logId), entry.toMap());
  }

  Future<void> log({
    required ActivityAction action,
    required String targetId,
    required AppUser actor,
    String? details,
  }) async {
    final entry = ActivityLogEntry(
      logId: '',
      action: action,
      targetId: targetId,
      performedBy: actor.uid,
      performedByName: actor.name,
      details: details,
    );
    await _col.add(entry.toMap());
  }

  /// Admin-only screen (SRS §3.4 / Screen 6). Rules also enforce this
  /// server-side — a non-admin query here would simply be denied.
  Stream<List<ActivityLogEntry>> recent({int limit = 50}) {
    return _col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ActivityLogEntry.fromDoc).toList());
  }
}
