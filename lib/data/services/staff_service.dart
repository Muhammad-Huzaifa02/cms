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
    await _col.doc(staffUid).update({'permissions': permissions.toMap()});
    await _activity.log(
      action: ActivityAction.staffPermissionsChanged,
      targetId: staffUid,
      actor: actor,
    );
  }

  Future<void> setActive({
    required String staffUid,
    required bool active,
    required AppUser actor,
  }) async {
    if (!actor.isAdmin) throw Exception('Only Admin can deactivate staff accounts.');
    await _col.doc(staffUid).update({'active': active});
    await _activity.log(
      action: ActivityAction.staffRemoved,
      targetId: staffUid,
      actor: actor,
      details: active ? 'reactivated' : 'deactivated',
    );
  }
}
