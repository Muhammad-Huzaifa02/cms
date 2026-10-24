import 'package:flutter_test/flutter_test.dart';
import 'package:cms/data/models/customer_model.dart';

void main() {
  const customer = Customer(
    accountNumber: '12345678901234',
    name: 'Muhammad Huzaifa',
    accountTitle: 'Huzaifa Enterprises',
    phone: '03001234567',
    cnic: '3520212345671',
    accountType: 'Current',
    address: 'Lahore, Pakistan',
    notes: 'VIP Customer',
    createdBy: 'admin_uid',
    updatedBy: 'admin_uid',
  );

  group('Customer Model - Masking Getters', () {
    test('masks CNIC showing only last 4 digits', () {
      expect(customer.maskedCnic, equals('•••••••••5671'));
      expect(customer.cnic.length, equals(13));
    });

    test('masks Account Number showing only last 4 digits', () {
      expect(customer.maskedAccountNumber, equals('••••••••••1234'));
      expect(customer.accountNumber.length, equals(14));
    });

    test('masks Phone showing only last 4 digits', () {
      expect(customer.maskedPhone, equals('•••••••4567'));
      expect(customer.phone.length, equals(11));
    });
  });

  group('Customer Model - Field-Isolated Last4 Getters', () {
    test('extracts phoneLast4 correctly', () {
      expect(customer.phoneLast4, equals('4567'));
    });

    test('extracts cnicLast4 correctly', () {
      expect(customer.cnicLast4, equals('5671'));
    });

    test('extracts accountNumberLast4 correctly', () {
      expect(customer.accountNumberLast4, equals('1234'));
    });
  });

  group('Customer Model - Search Word Generators', () {
    test('buildAccountTitleSearchWords includes word prefixes for title', () {
      final words = customer.buildAccountTitleSearchWords();
      expect(words, contains('huzaifa'));
      expect(words, contains('hu'));
      expect(words, contains('huz'));
      expect(words, contains('enterprises'));
    });

    test('buildSearchKeywords includes words from name and title', () {
      final keywords = customer.buildSearchKeywords();
      expect(keywords, contains('muhammad'));
      expect(keywords, contains('huzaifa'));
      expect(keywords, contains('4567')); // phone suffix
      expect(keywords, contains('5671')); // cnic suffix
      expect(keywords, contains('1234')); // account number suffix
    });
  });

  group('Customer Model - Serialization', () {
    test('toMap generates expected field dictionary', () {
      final map = customer.toMap(actingUid: 'acting_user_123', isNew: true);
      expect(map['accountNumber'], equals('12345678901234'));
      expect(map['name'], equals('Muhammad Huzaifa'));
      expect(map['accountTitle'], equals('Huzaifa Enterprises'));
      expect(map['phone'], equals('03001234567'));
      expect(map['cnic'], equals('3520212345671'));
      expect(map['phoneLast4'], equals('4567'));
      expect(map['cnicLast4'], equals('5671'));
      expect(map['accountNumberLast4'], equals('1234'));
      expect(map['createdBy'], equals('acting_user_123'));
      expect(map['updatedBy'], equals('acting_user_123'));
    });
  });
}
