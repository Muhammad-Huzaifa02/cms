import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// What a biometric attempt actually did — lets callers show a specific,
/// helpful message instead of a generic "failed", and distinguishes
/// "user cancelled" (not an error) from real failures.
enum BiometricResult {
  success,
  cancelled,
  noHardware,
  notEnrolled,
  lockedOut,
  otherError,
}

/// This is an APP-LOCK, not a password-replacement: Firebase already keeps
/// the person signed in across app restarts on its own (unrelated to this
/// class — normal Firebase Auth behavior). When enabled, a successful
/// fingerprint/Face ID check is required before that already-valid
/// session is allowed through — see BiometricLockScreen. No password, or
/// anything else sensitive, is ever stored here — only a per-account
/// on/off flag, and only ever after a real successful check.
///
/// The enabled flag is stored PER UID (`biometric_lock_enabled_<uid>`),
/// not globally. Without that, if Staff A enables biometric lock and later
/// Staff B signs into the same physical device, B would silently inherit
/// A's "locked" state despite never having enabled it themselves — a real
/// problem on a shared branch device with multiple staff accounts.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _keyFor(String uid) => 'biometric_lock_enabled_$uid';

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck || await _auth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isLockEnabled(String uid) async {
    try {
      final enabled = await _storage.read(key: _keyFor(uid));
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error reading biometric lock setting: $e');
      return false;
    }
  }

  Future<void> setLockEnabled(String uid, bool enabled) async {
    try {
      if (enabled) {
        await _storage.write(key: _keyFor(uid), value: 'true');
      } else {
        // Delete rather than write 'false' — "removes the local
        // biometric-login configuration" per spec, leaving nothing behind
        // for this account rather than an explicit off-flag.
        await _storage.delete(key: _keyFor(uid));
      }
    } catch (e) {
      debugPrint('Error saving biometric lock setting: $e');
    }
  }

  /// Never throws — every PlatformException case Android/iOS can raise
  /// here is mapped to a [BiometricResult] instead of crashing the caller.
  Future<BiometricResult> authenticate({String reason = 'Unlock CMS'}) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return success ? BiometricResult.success : BiometricResult.cancelled;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricResult.noHardware;
        case 'NotEnrolled':
          // Enrollment changed (or was never set up) since last time —
          // per spec, this should force normal authentication rather than
          // ever silently pass.
          return BiometricResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricResult.lockedOut;
        case 'UserCanceled':
        case 'user_canceled':
          return BiometricResult.cancelled;
        default:
          debugPrint('Biometric auth error [${e.code}]: ${e.message}');
          return BiometricResult.otherError;
      }
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return BiometricResult.otherError;
    }
  }
}

extension BiometricResultMessage on BiometricResult {
  /// User-facing message — deliberately says nothing about *why* in
  /// technical terms, just what to do next.
  String get message => switch (this) {
        BiometricResult.success => '',
        BiometricResult.cancelled => '',
        BiometricResult.noHardware => 'This device doesn\'t support biometric authentication.',
        BiometricResult.notEnrolled => 'No fingerprint or Face ID is set up on this device. Set one up in your device settings, or use your password.',
        BiometricResult.lockedOut => 'Too many attempts. Try again later, or use your password.',
        BiometricResult.otherError => 'Biometric authentication isn\'t available right now. Please use your password.',
      };
}
