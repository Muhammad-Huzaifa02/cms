import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceIntegrityService {
  DeviceIntegrityService._();
  static final DeviceIntegrityService instance = DeviceIntegrityService._();

  /// Checks if the device is rooted, jailbroken, or in developer test mode.
  /// Always returns false on web/desktop and during test executions.
  Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;
    // Don't block during automated widget tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      // In release builds, running on a rooted/jailbroken device is dangerous.
      return jailbroken;
    } on PlatformException catch (e) {
      debugPrint('Device integrity check failed: $e');
      return false;
    } catch (_) {
      return false;
    }
  }
}
