import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import 'activity_service.dart';

/// Everything here should only ever be reachable from Admin-gated screens.
/// Security Rules double-enforce this on the `users` collection
/// (`allow write: if isAdmin();`) so even a modified client can't abuse it.
class StaffService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activity = ActivityService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Stream<List<AppUser>> staffList() {
    return _col
        .where('isAdmin', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.map(AppUser.fromDoc).toList());
  }

  Future<void> updatePermissions({
    required String staffUid,
    required Permissions permissions,
    required AppUser actor,
  }) async {
    if (!actor.isAdmin) throw Exception('Only Admin can change staff permissions.');
    final userRef = _col.doc(staffUid);
    final eventId = _db.collection('activityLog').doc().id;
    await _db.runTransaction((transaction) async {
      final current = await transaction.get(userRef);
      if (!current.exists || current.data()?['isAdmin'] == true) {
        throw Exception('Staff account not found.');
      }
      final old = Permissions.fromMap(current.data()?['permissions']);
      if (old.view == permissions.view && old.add == permissions.add &&
          old.edit == permissions.edit && old.delete == permissions.delete) {
        return;
      }
      transaction.update(userRef, {
        'permissions': permissions.toMap(),
        'lastActivityId': eventId,
      });
      _activity.stageInTransaction(
        transaction,
        logId: eventId,
        action: ActivityAction.staffPermissionsChanged,
        targetId: staffUid,
        actor: actor,
      );
    });
  }

  Future<void> setActive({
    required String staffUid,
    required bool active,
    required AppUser actor,
  }) async {
    if (!actor.isAdmin) throw Exception('Only Admin can deactivate staff accounts.');
    final userRef = _col.doc(staffUid);
    final eventId = _db.collection('activityLog').doc().id;
    await _db.runTransaction((transaction) async {
      final current = await transaction.get(userRef);
      if (!current.exists || current.data()?['isAdmin'] == true) {
        throw Exception('Staff account not found.');
      }
      if (current.data()?['active'] == active) return;
      transaction.update(userRef, {
        'active': active,
        'lastActivityId': eventId,
      });
      _activity.stageInTransaction(
        transaction,
        logId: eventId,
        action: ActivityAction.staffRemoved,
        targetId: staffUid,
        actor: actor,
        details: active ? 'reactivated' : 'deactivated',
      );
    });
  }
}


