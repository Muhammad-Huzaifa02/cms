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

  // ---------------------------------------------------------------------
  // Dashboard stats — both use Firestore's server-side COUNT aggregation
  // (`.count().get()`), which returns just a number without downloading
  // any documents. This is deliberate: the collection could eventually
  // hold thousands of customers, and neither of these should ever pull
  // the whole collection just to display a number on the Dashboard.
  //
  // Only these two are implemented as real stats. An "Active/Inactive
  // customers" pair was requested elsewhere, but the Customer model has
  // no status/active field to compute that from (every record simply
  // exists or is deleted — see docs/TASKS.md) — showing those would mean
  // inventing a number, which the same spec explicitly asked not to do.
  // ---------------------------------------------------------------------

  Future<int> getTotalCustomersCount() async {
    final snap = await _col.count().get();
    return snap.count ?? 0;
  }

  Future<int> getNewCustomersThisMonthCount() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final snap = await _col.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth)).count().get();
    return snap.count ?? 0;
  }

  /// One lightweight `.count()` query per day for the last 7 days —
  /// 7 small server-side counts, never a download of customer documents.
  /// Returns oldest→newest. Deliberately fixed at 7 days rather than a
  /// selectable period (week/month/quarter/year): each additional period
  /// multiplies the query count, and a single always-useful view is a
  /// better performance/complexity trade-off than a rarely-used dropdown.
  Future<List<int>> getGrowthLast7Days() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = <int>[];
    for (int i = 6; i >= 0; i--) {
      final dayStart = today.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final snap = await _col
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(dayEnd))
          .count()
          .get();
      counts.add(snap.count ?? 0);
    }
    return counts;
  }

  /// Exact-match lookup by phone or CNIC, used for duplicate detection
  /// before creating/editing a customer. Relies on the fact that
  /// buildSearchKeywords() always includes the FULL cleaned value as one
  /// of its keywords (not just prefixes/suffixes), so arrayContains here
  /// matches only an exact phone/CNIC, never a partial one.
  Future<Customer?> findByPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    final snap = await _col.where('searchKeywords', arrayContains: clean).limit(5).get();
    final matches = snap.docs.map(Customer.fromDoc).where((c) => c.phone.replaceAll(RegExp(r'[^0-9]'), '') == clean);
    return matches.isEmpty ? null : matches.first;
  }

  Future<Customer?> findByCnic(String cnic) async {
    final clean = cnic.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    final snap = await _col.where('searchKeywords', arrayContains: clean).limit(5).get();
    final matches = snap.docs.map(Customer.fromDoc).where((c) => c.cnic.replaceAll(RegExp(r'[^0-9]'), '') == clean);
    return matches.isEmpty ? null : matches.first;
  }

  // ---------------------------------------------------------------------
  // Field-isolated search — each method queries EXACTLY ONE Firestore
  // field and nothing else. This is deliberate: the combined `search()`
  // above (and its shared `searchKeywords` array) can't tell two
  // different fields apart when they happen to share the same last-4
  // digits — a phone ending "4567" and a totally different customer's
  // CNIC ending "4567" would both match the same keyword. These methods
  // exist specifically so the Dashboard's "Search Customer By" flow can
  // guarantee that never happens.
  // ---------------------------------------------------------------------

  Future<List<Customer>> searchByAccountTitle(String title) async {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return [];
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final snap = await _col
        .where('accountTitleSearchWords', arrayContainsAny: words.take(30).toList())
        .limit(50)
        .get();
    final all = snap.docs.map(Customer.fromDoc);
    // Narrow to titles containing every word typed, same reasoning as the
    // multi-word branch in search() above — but checked ONLY against
    // accountTitle, never name or anything else.
    final narrowed = all.where((c) {
      final haystack = c.accountTitle.toLowerCase();
      return words.every((w) => haystack.contains(w));
    }).toList();
    return narrowed;
  }

  Future<List<Customer>> searchByAccountNumberLast4(String last4) async {
    final clean = last4.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 4) return [];
    final snap = await _col.where('accountNumberLast4', isEqualTo: clean).limit(50).get();
    return snap.docs.map(Customer.fromDoc).toList();
  }

  Future<List<Customer>> searchByPhoneLast4(String last4) async {
    final clean = last4.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 4) return [];
    final snap = await _col.where('phoneLast4', isEqualTo: clean).limit(50).get();
    return snap.docs.map(Customer.fromDoc).toList();
  }

  Future<List<Customer>> searchByCnicLast4(String last4) async {
    final clean = last4.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 4) return [];
    final snap = await _col.where('cnicLast4', isEqualTo: clean).limit(50).get();
    return snap.docs.map(Customer.fromDoc).toList();
  }

  Future<List<Customer>> searchByField(CustomerSearchField field, String query) {
    switch (field) {
      case CustomerSearchField.accountTitle:
        return searchByAccountTitle(query);
      case CustomerSearchField.accountNumber:
        return searchByAccountNumberLast4(query);
      case CustomerSearchField.phone:
        return searchByPhoneLast4(query);
      case CustomerSearchField.cnic:
        return searchByCnicLast4(query);
    }
  }

  /// One-time migration helper: customers created/edited before the
  /// field-isolated search fields existed won't have
  /// phoneLast4/cnicLast4/accountNumberLast4/accountTitleSearchWords set,
  /// so they won't show up in the new search until backfilled. Admin-only
  /// — re-saves every customer doc with these fields freshly computed.
  /// Safe to run more than once; it's idempotent.
  Future<int> backfillSearchFields(AppUser actor) async {
    if (!actor.isAdmin) throw Exception('Only Admin can run this.');
    final snap = await _col.get();
    var updated = 0;
    // Firestore batches cap at 500 writes — chunk defensively.
    for (var i = 0; i < snap.docs.length; i += 400) {
      final chunk = snap.docs.skip(i).take(400);
      final batch = _db.batch();
      for (final doc in chunk) {
        final customer = Customer.fromDoc(doc);
        batch.update(doc.reference, {
          'accountTitleSearchWords': customer.buildAccountTitleSearchWords(),
          'phoneLast4': customer.phoneLast4,
          'cnicLast4': customer.cnicLast4,
          'accountNumberLast4': customer.accountNumberLast4,
        });
        updated++;
      }
      await batch.commit();
    }
    return updated;
  }

  Future<void> addCustomer(Customer customer, AppUser actor) async {
    if (!actor.can('add')) throw Exception('You do not have permission to add customers.');
    final existing = await _col.doc(customer.accountNumber).get();
    if (existing.exists) {
      throw Exception('An account with this number already exists.');
    }
    final phoneMatch = await findByPhone(customer.phone);
    if (phoneMatch != null) {
      throw Exception('A customer with this phone number already exists (${phoneMatch.name}).');
    }
    final cnicMatch = await findByCnic(customer.cnic);
    if (cnicMatch != null) {
      throw Exception('A customer with this CNIC already exists (${cnicMatch.name}).');
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

  /// [originalPhone]/[originalCnic] are the values BEFORE this edit —
  /// duplicate checks only run if the person actually changed the value,
  /// so editing a customer's address doesn't spuriously flag their own
  /// unchanged phone/CNIC as "already in use".
  Future<void> updateCustomer(
    Customer customer,
    AppUser actor, {
    String? details,
    String? originalPhone,
    String? originalCnic,
  }) async {
    if (!actor.can('edit')) throw Exception('You do not have permission to edit customers.');
    if (originalPhone != null && originalPhone != customer.phone) {
      final phoneMatch = await findByPhone(customer.phone);
      if (phoneMatch != null && phoneMatch.accountNumber != customer.accountNumber) {
        throw Exception('A customer with this phone number already exists (${phoneMatch.name}).');
      }
    }
    if (originalCnic != null && originalCnic != customer.cnic) {
      final cnicMatch = await findByCnic(customer.cnic);
      if (cnicMatch != null && cnicMatch.accountNumber != customer.accountNumber) {
        throw Exception('A customer with this CNIC already exists (${cnicMatch.name}).');
      }
    }
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
