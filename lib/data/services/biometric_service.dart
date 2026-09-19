import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Biometric login used to work by storing the account's actual password
/// (encrypted at rest via flutter_secure_storage) and replaying it after a
/// fingerprint/Face ID check. That worked, but for a tool handling CNIC and
/// account data, storing a password at all — even encrypted — is a bigger
/// attack surface than necessary when there's a strictly better option.
///
/// This is now an APP-LOCK instead: Firebase already keeps you signed in
/// across app restarts on its own (that's normal, unrelated to this
/// class). When lock is enabled, a successful fingerprint/Face ID check is
/// required before that already-valid session is allowed to reach the
/// Dashboard — see BiometricLockScreen / main.dart's _AuthGate. No
/// password, or anything else sensitive, is ever stored here.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyLockEnabled = 'biometric_lock_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck || await _auth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isLockEnabled() async {
    try {
      final enabled = await _storage.read(key: _keyLockEnabled);
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error reading biometric lock setting: $e');
      return false;
    }
  }

  Future<void> setLockEnabled(bool enabled) async {
    try {
      await _storage.write(key: _keyLockEnabled, value: enabled.toString());
    } catch (e) {
      debugPrint('Error saving biometric lock setting: $e');
    }
  }

  Future<bool> authenticate({String reason = 'Unlock CMS'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
