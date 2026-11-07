/// Shared validation rules for Customer and Staff forms. Centralized here
/// so Add Customer, Edit Customer, and Add Staff all enforce identically —
/// duplicating this logic per-screen is how validation rules silently
/// drift apart over time.
class Validators {
  Validators._();

  static final _digitsOnly = RegExp(r'^[0-9]+$');
  static final _hasLetter = RegExp(r'[A-Za-z]');
  static final _ibnNoPattern = RegExp(r'^[A-Z0-9]{24}$');

  /// Required 24-character IBN identifier using uppercase ASCII letters
  /// and digits only.
  static String? ibnNo(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'IBN No. is required.';
    if (!_ibnNoPattern.hasMatch(v)) {
      return 'IBN No. must contain exactly 24 uppercase letters or digits.';
    }
    return null;
  }

  /// Pakistani mobile format: exactly 11 digits, digits only, starts
  /// with "03". Returns null when valid, an error message otherwise —
  /// the standard Flutter TextFormField validator contract.
  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required.';
    if (!_digitsOnly.hasMatch(v) || v.length != 11 || !v.startsWith('03')) {
      return 'Phone number must be a valid Pakistani mobile number with exactly 11 digits.';
    }
    return null;
  }

  /// Exactly 13 digits, digits only — no dashes, no spaces. Deliberately
  /// does not auto-strip separators the user typed; per spec, an
  /// incorrectly formatted CNIC should be rejected with a clear message,
  /// not silently "fixed".
  static String? cnic(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'CNIC is required.';
    if (!_digitsOnly.hasMatch(v) || v.length != 13) {
      return 'CNIC must contain exactly 13 digits.';
    }
    return null;
  }

  /// Exactly 14 digits, digits only. Note: this is the CUSTOMER-FACING
  /// bank account number field, distinct from the Firestore document ID
  /// (see Customer model docs) — both happen to be the same value in
  /// this app, but conceptually this validator is about the displayed
  /// account number's format, not Firestore's uniqueness guarantee.
  static String? accountNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account number is required.';
    if (!_digitsOnly.hasMatch(v) || v.length != 14) {
      return 'Account number must contain exactly 14 digits.';
    }
    return null;
  }

  /// A person's/company's/business's name on the account. Free text,
  /// but must contain at least one letter — rejects a purely numeric or
  /// symbols-only value someone might paste in by mistake.
  static String? accountTitle(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account Title is required.';
    if (!_hasLetter.hasMatch(v)) {
      return 'Account Title must contain a name.';
    }
    return null;
  }

  static String? requiredName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required.';
    return null;
  }

  static final _hasUpper = RegExp(r'[A-Z]');
  static final _hasLower = RegExp(r'[a-z]');
  static final _hasDigit = RegExp(r'[0-9]');
  static final _hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/`~]');

  /// Banking-grade password policy:
  /// - Minimum 8 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one number (0-9)
  /// - At least one special symbol (!@#$%^&*...)
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 8) return 'Password must be at least 8 characters long.';
    if (!_hasUpper.hasMatch(v)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!_hasLower.hasMatch(v)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!_hasDigit.hasMatch(v)) {
      return 'Password must contain at least one number (0-9).';
    }
    if (!_hasSpecial.hasMatch(v)) {
      return 'Password must contain at least one special character (e.g. @, #, \$, !).';
    }
    return null;
  }
}
