import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps 1:1 to a document in the `customers` collection.
/// Doc ID == accountNumber (guarantees uniqueness — see Data Model §3).
class Customer {
  final String accountNumber;
  final String name;
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

  const Customer({
    required this.accountNumber,
    required this.name,
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
  });

  /// last-4-digit masking used everywhere in the UI by default (SRS §5.1).
  String get maskedCnic {
    if (cnic.length < 4) return cnic;
    return '•••••-••••••-${cnic.substring(cnic.length - 1)}';
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    return '${'•' * (accountNumber.length - 4)}$visible';
  }

  /// Build search keywords for partial and exact matches on name, phone,
  /// CNIC, and account number. Supports prefix matching (search for "0300"
  /// finds "0300123...").
  List<String> buildSearchKeywords() {
    final keywords = <String>{};

    // 1. Individual words from name
    for (final w in name.toLowerCase().split(RegExp(r'\s+'))) {
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

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Customer(
      accountNumber: doc.id,
      name: data['name'] ?? '',
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
    );
  }

  Map<String, dynamic> toMap({required String actingUid, required bool isNew}) {
    final map = {
      'accountNumber': accountNumber,
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'accountType': accountType,
      'dateOpened': dateOpened != null ? Timestamp.fromDate(dateOpened!) : null,
      'address': address,
      'notes': notes,
      'searchKeywords': buildSearchKeywords(),
      'updatedBy': actingUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      map['createdBy'] = actingUid;
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
