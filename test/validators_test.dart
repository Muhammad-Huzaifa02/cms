import 'package:flutter_test/flutter_test.dart';
import 'package:cms/core/utils/validators.dart';

void main() {
  group('Validators - Phone', () {
    test('validates correct 11-digit 03xx Pakistani mobile number', () {
      expect(Validators.phone('03001234567'), isNull);
      expect(Validators.phone('03459876543'), isNull);
    });

    test('rejects empty or null phone number', () {
      expect(Validators.phone(''), equals('Phone number is required.'));
      expect(Validators.phone(null), equals('Phone number is required.'));
    });

    test('rejects phone numbers not starting with 03', () {
      expect(
        Validators.phone('04231234567'),
        equals('Phone number must be a valid Pakistani mobile number with exactly 11 digits.'),
      );
    });

    test('rejects phone numbers with non-digit characters or wrong length', () {
      expect(
        Validators.phone('0300-1234567'),
        equals('Phone number must be a valid Pakistani mobile number with exactly 11 digits.'),
      );
      expect(
        Validators.phone('0300123456'),
        equals('Phone number must be a valid Pakistani mobile number with exactly 11 digits.'),
      );
      expect(
        Validators.phone('030012345678'),
        equals('Phone number must be a valid Pakistani mobile number with exactly 11 digits.'),
      );
    });
  });

  group('Validators - CNIC', () {
    test('validates correct 13-digit CNIC', () {
      expect(Validators.cnic('3520212345671'), isNull);
    });

    test('rejects empty or null CNIC', () {
      expect(Validators.cnic(''), equals('CNIC is required.'));
      expect(Validators.cnic(null), equals('CNIC is required.'));
    });

    test('rejects CNIC with hyphens, spaces or wrong length', () {
      expect(
        Validators.cnic('35202-1234567-1'),
        equals('CNIC must contain exactly 13 digits.'),
      );
      expect(
        Validators.cnic('352021234567'),
        equals('CNIC must contain exactly 13 digits.'),
      );
    });
  });

  group('Validators - Account Number', () {
    test('validates correct 14-digit account number', () {
      expect(Validators.accountNumber('12345678901234'), isNull);
    });

    test('rejects empty, non-digit or incorrect length account number', () {
      expect(Validators.accountNumber(''), equals('Account number is required.'));
      expect(
        Validators.accountNumber('1234567890123'),
        equals('Account number must contain exactly 14 digits.'),
      );
      expect(
        Validators.accountNumber('123456789012345'),
        equals('Account number must contain exactly 14 digits.'),
      );
    });
  });

  group('Validators - IBN No.', () {
    test('accepts exactly 24 uppercase alphanumeric characters', () {
      expect(Validators.ibnNo('AB12CD34EF56GH78IJ90KL12'), isNull);
    });

    test('requires 24 uppercase alphanumeric characters', () {
      expect(Validators.ibnNo(''), equals('IBN No. is required.'));
      expect(Validators.ibnNo('ab12CD34EF56GH78IJ90KL12'), isNotNull);
      expect(Validators.ibnNo('AB12CD34EF56GH78IJ90KL1'), isNotNull);
      expect(Validators.ibnNo('AB12CD34EF56GH78IJ90KL123'), isNotNull);
      expect(Validators.ibnNo('AB12-CD34EF56GH78IJ90KL12'), isNotNull);
    });
  });

  group('Validators - Account Title & Required Name', () {
    test('validates account title containing letters', () {
      expect(Validators.accountTitle('Muhammad Huzaifa'), isNull);
      expect(Validators.accountTitle('Ali Traders'), isNull);
    });

    test('rejects empty or purely numeric/symbol account title', () {
      expect(Validators.accountTitle(''), equals('Account Title is required.'));
      expect(
        Validators.accountTitle('123456'),
        equals('Account Title must contain a name.'),
      );
    });

    test('validates required name field', () {
      expect(Validators.requiredName('Huzaifa'), isNull);
      expect(Validators.requiredName(''), equals('Name is required.'));
    });
  });
}
