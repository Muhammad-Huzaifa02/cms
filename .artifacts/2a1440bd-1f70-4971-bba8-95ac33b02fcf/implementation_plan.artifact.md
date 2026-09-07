# Professional Biometric Authentication Flow Implementation Plan

This plan outlines the steps to implement a secure and user-friendly biometric authentication flow in the CMS Flutter app, adhering to professional standards and explicit user consent requirements.

## Proposed Changes

### 1. Data Layer & Services

#### [MODIFY] [biometric_service.dart](file:///C:/Users/seith/StudioProjects/cms/lib/data/services/biometric_service.dart)
- Add `isBiometricEnabled()` to check secure storage for the user's preference.
- Add `setBiometricEnabled(bool)` to update the preference.
- Refactor `authenticate()` to provide more descriptive reasons and options.
- Ensure `saveCredentials` is only called when biometrics are explicitly enabled.

#### [MODIFY] [auth_service.dart](file:///C:/Users/seith/StudioProjects/cms/lib/data/services/auth_service.dart)
- Update `signInWithBiometrics()` to strictly check if biometrics are enabled by the user before attempting authentication.

---

### 2. Authentication UI

#### [MODIFY] [login_screen.dart](file:///C:/Users/seith/StudioProjects/cms/lib/modules/authentication/views/login_screen.dart)
- **Remove automatic credential saving**: Ensure credentials are NOT saved silently during normal login.
- **Implement "Offer Biometrics"**: After a successful manual login, if the device supports biometrics and they aren't enabled yet, show a dialog to offer enabling them.
- **Explicit Enablement**: If the user chooses "Enable", trigger a biometric challenge immediately to verify before saving credentials and preference.
- **Conditional Biometric Button**: Show the biometric login button only if `isBiometricEnabled()` is true.
- **Auto-prompt (Optional but good UX)**: Optionally show the biometric prompt on app start if enabled.

---

### 3. Settings & Profile

#### [MODIFY] [edit_profile_screen.dart](file:///C:/Users/seith/StudioProjects/cms/lib/modules/profile/views/edit_profile_screen.dart)
- Add a "Biometric Login" toggle switch.
- **Toggle ON flow**: Ask for the current password (or use if available) and perform a biometric challenge before enabling.
- **Toggle OFF flow**: Clear stored credentials and preference, and show a confirmation Snackbar.

---

### 4. Platform Configuration

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/seith/StudioProjects/cms/android/app/src/main/AndroidManifest.xml)
- Add `android.permission.USE_BIOMETRIC` if not already present (for broader compatibility, though `local_auth` 2.0+ handles it via AndroidX).

#### [MODIFY] [Info.plist](file:///C:/Users/seith/StudioProjects/cms/ios/Runner/Info.plist)
- Add `NSFaceIDUsageDescription` with a professional description.

## Verification Plan

### Automated Tests
- I will verify the logic in `BiometricService` and `AuthService` (if possible via unit tests if mocks are available).

### Manual Verification
1. **First Login**: Log in manually. Verify NO biometric prompt appears before login.
2. **Enable Offer**: After login, verify a dialog appears asking to enable biometrics.
3. **Consent**: Click "Cancel" on the offer. Verify biometrics are NOT enabled.
4. **Enablement**: Log in again, accept the offer, pass the biometric challenge. Verify "Biometric login enabled successfully" snackbar.
5. **Future Login**: Close and reopen the app. Verify the biometric icon appears on the Login screen (or a prompt triggers).
6. **Fallback**: Cancel the biometric prompt. Verify the user can still log in manually.
7. **Settings**: Go to "My Account", toggle "Biometric Login" OFF. Verify confirmation. Verify the biometric icon is gone from the Login screen.
8. **Re-enable**: Toggle "Biometric Login" ON in Settings. Pass challenge. Verify it works again.
