// This file is auto-generated — DO NOT hand-edit long-term.
//
// Generate the real version by running, from the project root:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command creates your Firebase project (or links an existing one),
// registers the Android/iOS apps, and overwrites this file with the real
// platform configuration (API keys, app IDs, etc. — safe to commit; these
// are not secret, access is controlled by Security Rules, not by hiding
// this file).
//
// A placeholder is provided below purely so the project compiles before
// you've run flutterfire configure.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not a target platform for CMS (SRS §2.3: Android + iOS only).');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  // Values below are pulled from your google-services.json
  // (project: customer-management-syst-36662). Re-run `flutterfire configure`
  // if you regenerate the Firebase project, or add the iOS block yourself
  // once you download GoogleService-Info.plist for iOS.
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCMtNZK-mQ02JE_-Y7Q4_CRajntO0miy0k',
    appId: '1:49081932178:android:521bbf7a3ab8d9e656894b',
    messagingSenderId: '49081932178',
    projectId: 'customer-management-syst-36662',
    storageBucket: 'customer-management-syst-36662.firebasestorage.app',
  );

  // iOS not yet configured — no GoogleService-Info.plist provided.
  // Download it from Firebase Console → Project Settings → your iOS app,
  // then fill these in (or just re-run flutterfire configure).
  static const ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '49081932178',
    projectId: 'customer-management-syst-36662',
    storageBucket: 'customer-management-syst-36662.firebasestorage.app',
    iosBundleId: 'com.example.cms',
  );
}
