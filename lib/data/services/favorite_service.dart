import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores each user's customer favorites in their private Firestore subcollection.
class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  Stream<Set<String>> watchIds(String uid) => _favorites(uid).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
      );

  Future<void> setFavorite({required String uid, required String customerId, required bool favorite}) async {
    final ref = _favorites(uid).doc(customerId);
    if (favorite) {
      await ref.set({'customerId': customerId, 'starredAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }
}
