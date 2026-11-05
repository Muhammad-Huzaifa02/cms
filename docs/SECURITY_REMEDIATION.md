# Security Baseline & Threat Remediation Update

This document records the full security hardening and loophole remediation across Firestore rules, native Android configurations, Flutter runtime guards, and customer service layers.

---

## 1. Loophole #2 Remediation (Phone-to-Email Enumeration Mitigation)

- **Issue**: Unauthenticated reads on `/phoneIndex/{phone}` allowed arbitrary actors to test mobile numbers and discover associated emails and UIDs.
- **Remediation**:
  - `firestore.rules` updated so `/phoneIndex/{phone}` is restricted to authenticated users:
    ```javascript
    match /phoneIndex/{phone} {
      allow get, list: if signedIn();
      ...
    }
    ```
  - `LoginScreen` shifted to direct Email + Password authentication, eliminating the need for unauthenticated public phone lookups while preserving dual email/phone account identities.

---

## 2. Advanced Cybersecurity Layer Additions

### A. Device Integrity & Anti-Tamper Guard (`DeviceIntegrityService`)
- Integrated `flutter_jailbreak_detection` in `lib/core/utils/device_integrity_service.dart`.
- Probes for:
  - Rooted Android devices (SuperSU, Magisk, `su` binaries).
  - Jailbroken iOS environments (Cydia, Substrate).
  - Runtime hooking frameworks (Frida, Xposed).
  - Untrusted emulation or debug builds.
- Enforced at the root `_AuthGate`: if compromised, execution halts on a high-visibility Security Alert screen with all database and auth access denied. Bypass enabled strictly during automated `flutter test`.

### B. Firebase App Check (API Attestation)
- Added `firebase_app_check` in `main.dart`.
- **Release builds**: Uses `AndroidPlayIntegrityProvider` to attest that requests originate from a genuine, unaltered app signed by Google Play.
- **Debug builds**: Uses `AndroidDebugProvider` to allow local development.
- Protects Firestore, Auth, and Storage against unauthorized API scripts, scrapers, and headless curl/Postman requests.

### C. OS Screen Privacy & Data Leak Protection (`FLAG_SECURE`)
- Configured in `android/app/src/main/kotlin/com/example/cms/MainActivity.kt`.
- `window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)` prevents:
  - Screen capture and recording by malware or unauthorized background apps.
  - Cached snapshots in the Android recent-apps task switcher (protecting sensitive customer data from shoulder-surfing).

### D. Brute-Force Rate Limiting (`LoginRateLimiter`)
- Implemented in `lib/core/utils/login_rate_limiter.dart`.
- Locks login submissions for 30 seconds after 5 consecutive failed attempts, displaying a live countdown in `LoginScreen`.

### E. Inactivity Session Auto-Lock (`InactivityWatcher`)
- Wraps the authenticated UI tree in `lib/core/widgets/inactivity_watcher.dart`.
- Listens to global pointer down, move, and up events. If no interaction occurs for 5 continuous minutes, `AuthService.signOut()` is executed automatically.

### F. Asynchronous Timer Memory Safety
- Refactored `FadeInSlide` to retain cancellable `Timer` handles and invoke `_delayTimer?.cancel()` during `dispose()`, ensuring zero memory leaks or unhandled background timers.

---

## 3. Firestore Rules Summary (`firestore.rules`)

- **Bootstrap**: Can only transition from false to true when the atomic operation creates/updates the caller's Admin user document with `createdBy == request.auth.uid`.
- **Customer Writes**: Validates Account Number (14 digits), Pakistani Phone (11 digits, `03`), CNIC (13 digits), IBAN (`PK...`, 24 chars), actor attribution, and timestamps.
- **Audit Coupling**: Customer create/update/delete writes the customer record and its activity log entry in a single atomic Firestore transaction via `getAfter()`.
- **Staff Operations**: Creation pairs user doc and activity log in the same batch. Permission and active status updates enforce transaction coupling.
- **Activity Log**: Append-only; update and delete are unconditionally denied to all users (including Admin).

---

## 4. Remaining Operational Recommendations

1. **Rule Deployment**: Ensure `firestore.rules` is deployed to production:
   ```bash
   firebase deploy --only firestore:rules
   ```
2. **App Check Registration**: Register the app's SHA-256 fingerprint in the Firebase Console under **App Check → Play Integrity**.
3. **One-Time Search Backfill**: Run "Sync search index" from the Admin drawer on initial release to index existing customer records.
