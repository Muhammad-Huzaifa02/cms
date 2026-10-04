import 'package:cloud_firestore/cloud_firestore.dart';

/// The four field-isolated search types (see docs — search must ONLY
/// ever query the one field the user explicitly picked, never several
/// fields at once, since last-4-digit suffixes can coincidentally match
/// across different fields for different customers).
enum CustomerSearchField { accountTitle, accountNumber, phone, cnic }

extension CustomerSearchFieldX on CustomerSearchField {
  String get label => switch (this) {
        CustomerSearchField.accountTitle => 'Account Title',
        CustomerSearchField.accountNumber => 'Account ID / Account Number',
        CustomerSearchField.phone => 'Phone Number',
        CustomerSearchField.cnic => 'CNIC',
      };

  /// Only Account Title takes free text — the other three are always
  /// exactly 4 digits.
  bool get isFreeText => this == CustomerSearchField.accountTitle;

  String get inputHint => switch (this) {
        CustomerSearchField.accountTitle => 'Enter customer account title',
        CustomerSearchField.accountNumber => 'Enter last 4 digits of Account ID',
        CustomerSearchField.phone => 'Enter last 4 digits of phone number',
        CustomerSearchField.cnic => 'Enter last 4 digits of CNIC',
      };
}

/// Maps 1:1 to a document in the `customers` collection.
/// Doc ID == accountNumber (guarantees uniqueness — see Data Model §3).
class Customer {
  final String accountNumber;
  final String name;
  final String accountTitle;
  final String phone;
  final String cnic;
  final String accountType;
  final DateTime? dateOpened;
  final String? address;
  final String? notes;
  final String createdBy;
  final DateTime? createdAt;
  final String updatedBy;
  final DateTime? updatedAt;
  final String status;
  final String? shopId;

  const Customer({
    required this.accountNumber,
    required this.name,
    required this.accountTitle,
    required this.phone,
    required this.cnic,
    required this.accountType,
    this.dateOpened,
    this.address,
    this.notes,
    required this.createdBy,
    this.createdAt,
    required this.updatedBy,
    this.updatedAt,
    this.status = 'Active',
    this.shopId,
  });

  /// last-4-digit masking used everywhere in the UI by default (SRS §5.1).
  String get maskedCnic {
    if (cnic.length <= 4) return cnic;
    final visible = cnic.substring(cnic.length - 4);
    return '${'•' * (cnic.length - 4)}$visible';
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    return '${'•' * (accountNumber.length - 4)}$visible';
  }

  String get maskedPhone {
    if (phone.length <= 4) return phone;
    final visible = phone.substring(phone.length - 4);
    return '${'•' * (phone.length - 4)}$visible';
  }

  /// Build search keywords for partial and exact matches on name, phone,
  /// CNIC, and account number. Supports prefix matching (search for "0300"
  /// finds "0300123..."). Kept for the Dashboard's general free-text
  /// search box. NOT used by the field-isolated search screen — see
  /// accountTitleSearchWords/phoneLast4/cnicLast4/accountNumberLast4
  /// below, which exist specifically because this shared array can't tell
  /// two different fields apart when they happen to share a suffix (a
  /// phone and a CNIC both ending "4567" both land in this same array).
  List<String> buildSearchKeywords() {
    final keywords = <String>{};

    // 1. Individual words from name AND account title (e.g. "Ali Traders"
    // is searchable the same way a person's name is)
    for (final w in [...name.toLowerCase().split(RegExp(r'\s+')), ...accountTitle.toLowerCase().split(RegExp(r'\s+'))]) {
      if (w.length > 1) {
        // Add full word
        keywords.add(w);
        // Add prefixes for partial name search (e.g., "huz" finds "huzaifa")
        for (int i = 2; i <= w.length; i++) {
          keywords.add(w.substring(0, i));
        }
      }
    }

    // 2. Phone number partials (from the end and start to catch common search patterns)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 3; i <= cleanPhone.length; i++) {
      keywords.add(cleanPhone.substring(0, i));
      keywords.add(cleanPhone.substring(cleanPhone.length - i));
    }

    // 3. CNIC partials (usually people search for the last 5 digits)
    final cleanCnic = cnic.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 4; i <= cleanCnic.length; i++) {
      keywords.add(cleanCnic.substring(0, i));
      keywords.add(cleanCnic.substring(cleanCnic.length - i));
    }

    // 4. Account Number partials
    for (int i = 3; i <= accountNumber.length; i++) {
      keywords.add(accountNumber.substring(0, i).toLowerCase());
      keywords.add(accountNumber.substring(accountNumber.length - i).toLowerCase());
    }

    return keywords.toList();
  }

  /// Word-prefixes derived ONLY from accountTitle (unlike
  /// buildSearchKeywords, which also mixes in `name`) — this is what
  /// backs the field-isolated "Search by Account Title" option, so a
  /// title search can never accidentally match on the customer's `name`
  /// field or anything else.
  List<String> buildAccountTitleSearchWords() {
    final keywords = <String>{};
    for (final w in accountTitle.toLowerCase().split(RegExp(r'\s+'))) {
      if (w.length > 1) {
        keywords.add(w);
        for (int i = 2; i <= w.length; i++) {
          keywords.add(w.substring(0, i));
        }
      }
    }
    return keywords.toList();
  }

  static String _cleanDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// Last-4-digits values for the field-isolated search screen. Each is
  /// its own dedicated Firestore field — deliberately NOT combined into
  /// any shared array — so a query on one can never match a different
  /// field that happens to share the same last 4 digits.
  String get phoneLast4 {
    final clean = _cleanDigits(phone);
    return clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
  }

  String get cnicLast4 {
    final clean = _cleanDigits(cnic);
    return clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
  }

  String get accountNumberLast4 {
    final clean = _cleanDigits(accountNumber);
    return clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
  }

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Customer document is empty (ID: ${doc.id})');
    }
    return Customer(
      accountNumber: doc.id,
      name: data['name'] ?? '',
      accountTitle: data['accountTitle'] ?? '',
      phone: data['phone'] ?? '',
      cnic: data['cnic'] ?? '',
      accountType: data['accountType'] ?? 'Current',
      dateOpened: (data['dateOpened'] as Timestamp?)?.toDate(),
      address: data['address'],
      notes: data['notes'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'Active',
      shopId: data['shopId'],
    );
  }

  Map<String, dynamic> toMap({required String actingUid, required bool isNew, String? targetShopId}) {
    final openedDate = dateOpened;
    final map = <String, dynamic>{
      'accountNumber': accountNumber,
      'name': name,
      'accountTitle': accountTitle,
      'phone': phone,
      'cnic': cnic,
      'accountType': accountType,
      'dateOpened': openedDate != null ? Timestamp.fromDate(openedDate) : null,
      'address': address,
      'notes': notes,
      'status': status,
      'searchKeywords': buildSearchKeywords(),
      // Field-isolated search support — see the doc comments above each
      // getter/method for why these are separate from searchKeywords.
      'accountTitleSearchWords': buildAccountTitleSearchWords(),
      'phoneLast4': phoneLast4,
      'cnicLast4': cnicLast4,
      'accountNumberLast4': accountNumberLast4,
      'updatedBy': actingUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (shopId != null) {
      map['shopId'] = shopId;
    } else if (targetShopId != null) {
      map['shopId'] = targetShopId;
    }
    if (isNew) {
      map['createdBy'] = actingUid;
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
