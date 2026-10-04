import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../models/dashboard_stats_model.dart';
import 'activity_service.dart';

/// All reads/writes here are additionally enforced server-side by
/// Firestore Security Rules — the permission checks in this class prevent
/// bad UI states, the rules prevent bad actors.
class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activity = ActivityService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('customers');

  Stream<List<Customer>> recentCustomers({int limit = 20, String? shopId}) {
    Query<Map<String, dynamic>> q = _col.orderBy('updatedAt', descending: true);
    if (shopId != null && shopId.isNotEmpty) {
      q = q.where('shopId', isEqualTo: shopId);
    }
    return q.limit(limit).snapshots().map((s) => s.docs.map(Customer.fromDoc).toList());
  }

  /// Calculates real-time dashboard analytics using efficient Firestore count()
  /// aggregations to avoid reading thousands of full documents.
  Future<DashboardStats> getDashboardStats(String shopId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    Query<Map<String, dynamic>> baseQuery = _col;
    if (shopId.isNotEmpty) {
      final testSnap = await _col.where('shopId', isEqualTo: shopId).limit(1).get();
      if (testSnap.docs.isNotEmpty) {
        baseQuery = _col.where('shopId', isEqualTo: shopId);
      }
    }

    try {
      final totalSnap = await baseQuery.count().get();
      final totalCount = totalSnap.count ?? 0;

      final activeSnap = await baseQuery.where('status', isEqualTo: 'Active').count().get();
      int activeCount = activeSnap.count ?? 0;

      final inactiveSnap = await baseQuery.where('status', isEqualTo: 'Inactive').count().get();
      int inactiveCount = inactiveSnap.count ?? 0;

      if (activeCount == 0 && inactiveCount == 0 && totalCount > 0) {
        activeCount = totalCount;
      } else if (activeCount + inactiveCount < totalCount) {
        activeCount = totalCount - inactiveCount;
      }

      final newThisMonthSnap = await baseQuery
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get();
      final newThisMonthCount = newThisMonthSnap.count ?? 0;

      final newLastMonthSnap = await baseQuery
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth))
          .where('createdAt', isLessThan: Timestamp.fromDate(startOfMonth))
          .count()
          .get();
      final newLastMonthCount = newLastMonthSnap.count ?? 0;

      double? growthPercentage;
      if (newLastMonthCount > 0) {
        growthPercentage = ((newThisMonthCount - newLastMonthCount) / newLastMonthCount) * 100;
      } else if (newThisMonthCount > 0) {
        growthPercentage = 100.0;
      }

      return DashboardStats(
        totalCustomers: totalCount,
        newThisMonth: newThisMonthCount,
        activeCustomers: activeCount,
        inactiveCustomers: inactiveCount,
        monthlyGrowthPercentage: growthPercentage,
        newLastMonth: newLastMonthCount,
      );
    } catch (e) {
      final snap = await baseQuery.limit(5000).get();
      final docs = snap.docs.map(Customer.fromDoc).toList();

      final total = docs.length;
      final active = docs.where((c) => c.status != 'Inactive').length;
      final inactive = docs.where((c) => c.status == 'Inactive').length;

      final thisMonth = docs.where((c) => c.createdAt != null && c.createdAt!.isAfter(startOfMonth)).length;
      final lastMonth = docs.where((c) {
        if (c.createdAt == null) return false;
        return c.createdAt!.isAfter(startOfLastMonth) && c.createdAt!.isBefore(startOfMonth);
      }).length;

      double? pct;
      if (lastMonth > 0) {
        pct = ((thisMonth - lastMonth) / lastMonth) * 100;
      } else if (thisMonth > 0) {
        pct = 100.0;
      }

      return DashboardStats(
        totalCustomers: total,
        newThisMonth: thisMonth,
        activeCustomers: active,
        inactiveCustomers: inactive,
        monthlyGrowthPercentage: pct,
        newLastMonth: lastMonth,
      );
    }
  }

  /// Calculates customer growth chart points for the selected time period.
  Future<List<GrowthPoint>> getGrowthData(String shopId, GrowthPeriod period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case GrowthPeriod.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case GrowthPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case GrowthPeriod.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case GrowthPeriod.last3Months:
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case GrowthPeriod.thisYear:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    Query<Map<String, dynamic>> baseQuery = _col;
    if (shopId.isNotEmpty) {
      final testSnap = await _col.where('shopId', isEqualTo: shopId).limit(1).get();
      if (testSnap.docs.isNotEmpty) {
        baseQuery = _col.where('shopId', isEqualTo: shopId);
      }
    }

    final snap = await baseQuery
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final customers = snap.docs.map(Customer.fromDoc).toList();

    if (period == GrowthPeriod.thisWeek) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return List.generate(7, (i) {
        final dayDate = startDate.add(Duration(days: i));
        final label = days[i];
        final count = customers.where((c) {
          if (c.createdAt == null) return false;
          return c.createdAt!.year == dayDate.year &&
              c.createdAt!.month == dayDate.month &&
              c.createdAt!.day == dayDate.day;
        }).length;
        return GrowthPoint(label: label, count: count, date: dayDate);
      });
    } else if (period == GrowthPeriod.thisMonth || period == GrowthPeriod.lastMonth) {
      final daysInMonth = DateUtils.getDaysInMonth(startDate.year, startDate.month);
      const intervals = 6;
      final step = (daysInMonth / intervals).ceil();
      final points = <GrowthPoint>[];

      for (int i = 0; i < intervals; i++) {
        final startDay = (i * step) + 1;
        final endDay = ((i + 1) * step).clamp(1, daysInMonth);
        if (startDay > daysInMonth) break;

        final label = 'Day $startDay-$endDay';
        final count = customers.where((c) {
          if (c.createdAt == null) return false;
          return c.createdAt!.year == startDate.year &&
              c.createdAt!.month == startDate.month &&
              c.createdAt!.day >= startDay &&
              c.createdAt!.day <= endDay;
        }).length;

        points.add(GrowthPoint(label: label, count: count, date: DateTime(startDate.year, startDate.month, startDay)));
      }
      return points;
    } else {
      final months = <GrowthPoint>[];
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      DateTime curr = DateTime(startDate.year, startDate.month, 1);

      while (!curr.isAfter(endDate)) {
        final label = monthNames[curr.month - 1];
        final mYear = curr.year;
        final mMonth = curr.month;
        final count = customers.where((c) {
          if (c.createdAt == null) return false;
          return c.createdAt!.year == mYear && c.createdAt!.month == mMonth;
        }).length;

        months.add(GrowthPoint(label: label, count: count, date: curr));
        curr = DateTime(curr.year, curr.month + 1, 1);
      }
      return months;
    }
  }

  /// Field-specific customer search with multi-shop isolation support.
  Future<List<Customer>> searchByField(dynamic field, String query, {String? shopId}) {
    String fieldName;
    if (field is CustomerSearchField) {
      fieldName = field.label;
    } else {
      fieldName = field.toString();
    }
    return search(query, searchField: fieldName, shopId: shopId);
  }

  Future<List<Customer>> search(String query, {String? searchField, String? shopId}) async {
    String q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final cleanDigits = q.replaceAll(RegExp(r'[^0-9]'), '');

    if (searchField != null && searchField != 'All') {
      final snap = await _col.limit(200).get();
      List<Customer> all = snap.docs.map(Customer.fromDoc).toList();

      if (shopId != null && shopId.isNotEmpty) {
        all = all.where((c) => c.shopId == null || c.shopId == shopId).toList();
      }

      switch (searchField) {
        case 'Phone Number':
        case 'Phone':
          return all.where((c) {
            final cleanPhone = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
            return cleanPhone.endsWith(cleanDigits) || cleanPhone.contains(cleanDigits);
          }).toList();

        case 'CNIC':
          return all.where((c) {
            final cleanCnic = c.cnic.replaceAll(RegExp(r'[^0-9]'), '');
            return cleanCnic.endsWith(cleanDigits) || cleanCnic.contains(cleanDigits);
          }).toList();

        case 'Account Number':
        case 'Account ID':
          return all.where((c) {
            final cleanAcc = c.accountNumber.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
            return cleanAcc.endsWith(q) || cleanAcc.contains(q);
          }).toList();

        case 'Account Title':
          return all.where((c) {
            final title = c.accountTitle.toLowerCase();
            final name = c.name.toLowerCase();
            return title.contains(q) || name.contains(q);
          }).toList();

        default:
          break;
      }
    }

    if (RegExp(r'^[0-9\-\s]+$').hasMatch(q)) {
      q = cleanDigits;
    }

    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    List<Customer> results = [];
    if (words.length > 1) {
      final snap = await _col
          .where('searchKeywords', arrayContainsAny: words.take(30).toList())
          .limit(50)
          .get();
      final all = snap.docs.map(Customer.fromDoc);
      results = all.where((c) {
        final haystack = '${c.name} ${c.accountTitle}'.toLowerCase();
        return words.every((w) => haystack.contains(w));
      }).toList();
    }

    if (results.isEmpty) {
      final snap = await _col
          .where('searchKeywords', arrayContains: q)
          .limit(30)
          .get();
      if (snap.docs.isNotEmpty) {
        results = snap.docs.map(Customer.fromDoc).toList();
      } else {
        final byAccount = await _col
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: q)
            .where(FieldPath.documentId, isLessThan: '$q\uf8ff')
            .limit(30)
            .get();
        results = byAccount.docs.map(Customer.fromDoc).toList();
      }
    }

    if (shopId != null && shopId.isNotEmpty) {
      results = results.where((c) => c.shopId == null || c.shopId == shopId).toList();
    }

    return results;
  }

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
          customer.toMap(actingUid: actor.uid, isNew: true, targetShopId: actor.shopId),
        );
    await _activity.log(
      action: ActivityAction.customerCreated,
      targetId: customer.accountNumber,
      actor: actor,
    );
  }

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
          customer.toMap(actingUid: actor.uid, isNew: false, targetShopId: actor.shopId),
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
