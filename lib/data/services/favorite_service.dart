import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores each user's customer favorites in their private user profile document.
class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, Future<void>> _legacyMigrations = {};

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> _migrateLegacyFavorites(String uid) =>
      _legacyMigrations.putIfAbsent(uid, () async {
        try {
          final legacy = await _user(uid).collection('favorites').get();
          final ids = legacy.docs.map((doc) => doc.id).toList();
          if (ids.isNotEmpty) {
            await _user(uid).update({
              'favoriteCustomerIds': FieldValue.arrayUnion(ids),
            });
          }
        } on FirebaseException {
          // Existing installs may have no legacy favorites collection or may
          // temporarily be offline. The profile stream remains the source of
          // truth for new favorite changes.
        }
      });

  Stream<Set<String>> watchIds(String uid) async* {
    await _migrateLegacyFavorites(uid);
    yield* _user(uid).snapshots().map((snapshot) {
      final favorites = snapshot.data()?['favoriteCustomerIds'];
      if (favorites is! Iterable) return <String>{};
      return favorites.whereType<String>().toSet();
    });
  }

  Future<void> setFavorite({required String uid, required String customerId, required bool favorite}) async {
    final ref = _user(uid);
    if (favorite) {
      await ref.update({
        'favoriteCustomerIds': FieldValue.arrayUnion([customerId]),
      });
    } else {
      await ref.update({
        'favoriteCustomerIds': FieldValue.arrayRemove([customerId]),
      });
    }
  }
}
