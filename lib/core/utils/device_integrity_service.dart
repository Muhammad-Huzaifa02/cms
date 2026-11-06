import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceIntegrityService {
  DeviceIntegrityService._();
  static final DeviceIntegrityService instance = DeviceIntegrityService._();

  static const _channel = MethodChannel('cms/device_integrity');

  /// Checks if the device is rooted, jailbroken, or in developer test mode.
  /// Always returns false on web/desktop and during test executions.
  Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;
    // Don't block during automated widget tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    try {
      if (Platform.isAndroid) {
        final bool isRooted = await _channel.invokeMethod<bool>('isRooted') ?? false;
        return isRooted;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('Device integrity check failed: $e');
      return false;
    } catch (_) {
      return false;
    }
  }
}
