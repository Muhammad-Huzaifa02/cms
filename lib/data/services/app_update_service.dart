import 'package:cloud_firestore/cloud_firestore.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForced;
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String downloadUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForced,
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

/// Service to check for in-app updates against Firestore app metadata config.
class AppUpdateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String currentAppVersion = '1.0.0';

  Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final doc = await _db.collection('system').doc('appConfig').get();
      if (!doc.exists || doc.data() == null) {
        return const AppUpdateInfo(
          hasUpdate: false,
          isForced: false,
          latestVersion: currentAppVersion,
          currentVersion: currentAppVersion,
          releaseNotes: '',
          downloadUrl: '',
        );
      }

      final data = doc.data()!;
      final latestVersion = (data['latestVersion'] ?? currentAppVersion).toString();
      final minVersion = (data['minRequiredVersion'] ?? currentAppVersion).toString();
      final releaseNotes = (data['releaseNotes'] ?? 'Performance improvements and security updates.').toString();
      final downloadUrl = (data['downloadUrl'] ?? '').toString();

      final hasUpdate = _isVersionHigher(latestVersion, currentAppVersion);
      final isForced = _isVersionHigher(minVersion, currentAppVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForced: isForced,
        latestVersion: latestVersion,
        currentVersion: currentAppVersion,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return const AppUpdateInfo(
        hasUpdate: false,
        isForced: false,
        latestVersion: currentAppVersion,
        currentVersion: currentAppVersion,
        releaseNotes: '',
        downloadUrl: '',
      );
    }
  }

  bool _isVersionHigher(String serverVer, String localVer) {
    try {
      final sParts = serverVer.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final lParts = localVer.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      for (var i = 0; i < 3; i++) {
        final s = i < sParts.length ? sParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (s > l) return true;
        if (s < l) return false;
      }
    } catch (_) {}
    return false;
  }
}
