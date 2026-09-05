import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import 'activity_service.dart';

/// All reads/writes here are additionally enforced server-side by
/// Firestore Security Rules (see Data Model §5) — the permission checks
/// in this class prevent bad UI states, the rules prevent bad actors.
class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activity = ActivityService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('customers');

  Stream<List<Customer>> recentCustomers({int limit = 20}) {
    return _col
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Customer.fromDoc).toList());
  }

  /// denormalized `searchKeywords` array (Data Model §3). Works for exact
  /// word / number matches on name-words, phone, cnic, and account number.
  /// Automatically strips dashes/spaces from numeric-looking queries to
  /// ensure they match the clean index.
  Future<List<Customer>> search(String query) async {
    String q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // If it looks like a number search (CNIC, phone, account), strip
    // separators so it matches the clean index keywords.
    if (RegExp(r'^[0-9\-\s]+$').hasMatch(q)) {
      q = q.replaceAll(RegExp(r'[^0-9]'), '');
    }

    final snap = await _col
        .where('searchKeywords', arrayContains: q)
        .limit(30)
        .get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.map(Customer.fromDoc).toList();
    }
    // Fallback: prefix match directly on accountNumber (doc ID) for
    // partial account-number lookups that don't hit the keyword index.
    final byAccount = await _col
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: q)
        .where(FieldPath.documentId, isLessThan: '$q\uf8ff')
        .limit(30)
        .get();
    return byAccount.docs.map(Customer.fromDoc).toList();
  }

  Future<void> addCustomer(Customer customer, AppUser actor) async {
    if (!actor.can('add')) throw Exception('You do not have permission to add customers.');
    final existing = await _col.doc(customer.accountNumber).get();
    if (existing.exists) {
      throw Exception('An account with this number already exists.');
    }
    await _col.doc(customer.accountNumber).set(
          customer.toMap(actingUid: actor.uid, isNew: true),
        );
    await _activity.log(
      action: ActivityAction.customerCreated,
      targetId: customer.accountNumber,
      actor: actor,
    );
  }

  Future<void> updateCustomer(Customer customer, AppUser actor, {String? details}) async {
    if (!actor.can('edit')) throw Exception('You do not have permission to edit customers.');
    await _col.doc(customer.accountNumber).update(
          customer.toMap(actingUid: actor.uid, isNew: false),
        );
    await _activity.log(
      action: ActivityAction.customerUpdated,
      targetId: customer.accountNumber,
      actor: actor,
      details: details,
    );
  }

  Future<void> deleteCustomer(String accountNumber, AppUser actor) async {
    if (!actor.can('delete')) throw Exception('You do not have permission to delete customers.');
    await _col.doc(accountNumber).delete();
    await _activity.log(
      action: ActivityAction.customerDeleted,
      targetId: accountNumber,
      actor: actor,
    );
  }
}
