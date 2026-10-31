import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores each user's customer favorites in their private user profile document.
class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Set<String> _migrationsInFlight = {};

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  void _migrateLegacyFavoritesInBackground(String uid) {
    if (!_migrationsInFlight.add(uid)) return;
    _migrateLegacyFavorites(uid)
        .catchError((Object _) {})
        .whenComplete(() => _migrationsInFlight.remove(uid));
  }

  Future<void> _migrateLegacyFavorites(String uid) async {
    try {
      final legacy = await _user(uid).collection('favorites').get();
      final ids = legacy.docs.map((doc) => doc.id).toList();
      await _user(uid).update({
        'favoriteCustomerIds': FieldValue.arrayUnion(ids),
        'favoritesMigrated': true,
      });
    } on FirebaseException {
      // Continue showing the current profile favorites if this one-time
      // migration cannot run; a later profile update can retry it.
    }
  }

  Stream<Set<String>> watchIds(String uid) => _user(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['favoritesMigrated'] != true) {
        _migrateLegacyFavoritesInBackground(uid);
      }
      final favorites = data?['favoriteCustomerIds'];
      if (favorites is! Iterable) return <String>{};
      return favorites.whereType<String>().toSet();
    });

  Future<void> setFavorite({required String uid, required String customerId, required bool favorite}) async {
    final ref = _user(uid);
    if (favorite) {
      await ref.update({
        'favoriteCustomerIds': FieldValue.arrayUnion([customerId]),
        'favoritesMigrated': true,
      });
    } else {
      await ref.update({
        'favoriteCustomerIds': FieldValue.arrayRemove([customerId]),
        'favoritesMigrated': true,
      });
    }
  }
}
