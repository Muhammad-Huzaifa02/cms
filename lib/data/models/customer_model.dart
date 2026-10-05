import 'package:cloud_firestore/cloud_firestore.dart';

/// The four field-isolated search types.
enum CustomerSearchField { accountTitle, accountNumber, phone, cnic }

extension CustomerSearchFieldX on CustomerSearchField {
  String get label => switch (this) {
        CustomerSearchField.accountTitle => 'Account Title',
        CustomerSearchField.accountNumber => 'Account ID / Account Number',
        CustomerSearchField.phone => 'Phone Number',
        CustomerSearchField.cnic => 'CNIC',
      };

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

  List<String> buildSearchKeywords() {
    final keywords = <String>{};

    for (final w in [...name.toLowerCase().split(RegExp(r'\s+')), ...accountTitle.toLowerCase().split(RegExp(r'\s+'))]) {
      if (w.length > 1) {
        keywords.add(w);
        for (int i = 2; i <= w.length; i++) {
          keywords.add(w.substring(0, i));
        }
      }
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 3; i <= cleanPhone.length; i++) {
      keywords.add(cleanPhone.substring(0, i));
      keywords.add(cleanPhone.substring(cleanPhone.length - i));
    }

    final cleanCnic = cnic.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 4; i <= cleanCnic.length; i++) {
      keywords.add(cleanCnic.substring(0, i));
      keywords.add(cleanCnic.substring(cleanCnic.length - i));
    }

    for (int i = 3; i <= accountNumber.length; i++) {
      keywords.add(accountNumber.substring(0, i).toLowerCase());
      keywords.add(accountNumber.substring(accountNumber.length - i).toLowerCase());
    }

    return keywords.toList();
  }

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
