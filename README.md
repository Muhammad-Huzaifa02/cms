# CMS — Customer Management System

Branch customer lookup, identity verification, and record management tool — independent of core banking systems.

---

## Features

- **Cybersecurity & Threat Hardening**:
  - **Device Integrity Guard**: Blocks execution on rooted, jailbroken, hooked (Frida/Xposed), or tampered devices.
  - **Firebase App Check**: Play Integrity attestation in production and debug token verification in development to block automated API abuse and scraping.
  - **Screen Capture & App Switcher Privacy Shield (`FLAG_SECURE`)**: Prevents screenshots, video captures, and masks recent app previews.
  - **Inactivity Session Auto-Lock**: Automatically terminates active sessions after 5 minutes of continuous user inactivity.
  - **Brute-Force Rate Limiter**: Locks out authentication for 30 seconds after 5 consecutive failed login attempts.
- **Dual Authentication**: Sign in with verified email or Pakistani mobile number (`03xx-xxxxxxx`) and password, secured against unauthenticated phone enumeration.
- **First-Time Self-Serve Admin Bootstrap**: First-run setup directly inside the app to create the branch manager (Admin) account without Firebase console steps.
- **Staff Management & Profile View**: Admin can view staff profiles, toggle individual permissions (`view`, `add`, `edit`, `delete`), and activate/deactivate accounts.
- **Comprehensive Customer Records**:
  - Pakistani Mobile (`03xx-xxxxxxx`, 11 digits), CNIC (13 digits), Account Number (14 digits), and IBAN (24 characters, `PK...`).
  - Gender (`Male`, `Female`, `Other`), Account Status (`Active`, `Inactive`, `Dormant`, `Blocked`), and optional customer Email.
  - Duplicate detection on Phone and CNIC.
- **Role-Gated & View-Only Contexts**: Customer editing is strictly restricted to Customer Management (`allowEditAction: true`). Dashboard recent cards and Search Results remain strictly view-only to prevent accidental modifications during lookups.
- **Dashboard Recent Customers**: Prominently displays `Account Title`, Account Number, and masked identifiers.
- **Field-Isolated Search**: Search customers strictly by exact fields (`Account Title`, `Account Number`, `Phone`, or `CNIC`) with 4-digit last-four lookup and dedicated index backfill.
- **Data Masking & Security**: CNIC, Account Number, and Phone masked by default (showing last 4 digits) with tap-to-reveal.
- **Redesigned Biometric App-Lock**: Modern circular vault UI with real-time sensor status indicator, per-user UID isolation, and safe fallback.
- **Adaptive Responsive Typography**: Global font scaler clamped between `0.85` and `1.15` to preserve layout integrity regardless of OS accessibility font size settings.
- **Excel & PDF Export**: Admin-only customer list export including Account Title, IBAN, Gender, Status, and Email, complete with audit logging.
- **Append-Only Activity Audit Log**: Every customer addition, update, deletion, staff permission change, and export is logged in an immutable audit trail.

---

## Project Structure

```
lib/
  main.dart                  # Application entry point, App Check, integrity guard, auth gate & lock gate
  firebase_options.dart      # Firebase SDK options
  core/                      # Shared theme, validators, and UI components
    theme/app_theme.dart     # Brand color palette and global widget styling
    utils/
      validators.dart        # Strict Pakistani format validators (phone, CNIC, account, IBAN)
      device_integrity_service.dart # Hardware & environment root/jailbreak detection
      login_rate_limiter.dart# Brute-force rate limiter (5 fails / 30s lockout)
    widgets/                 # Reusable UI components (InactivityWatcher, BiometricLockScreen, SectionCard, etc.)
  data/
    models/                  # AppUser, Customer, ActivityLogEntry
    services/                # AuthService, CustomerService, StaffService, ActivityService, ExportService, BiometricService
  modules/
    authentication/views/    # LoginScreen, CreateAdminScreen
    home/views/              # DashboardScreen, StaffManagementScreen, StaffProfileScreen, AddStaffScreen, ActivityLogScreen
    customers/views/         # AddCustomerScreen, CustomerDetailScreen, CustomerManagementScreen, SearchCustomerScreen, SearchResultsScreen
    profile/views/           # EditProfileScreen (My Account)
  routes/app_routes.dart     # Central route definitions
android/                     # Modern Android build setup (Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20)
firestore.rules              # Security rules for Cloud Firestore
test/                        # Unit and widget test suite (29/29 passing)
```

---

## Getting Started

### 1. Prerequisites
- **Flutter SDK** `>=3.3.0 <4.0.0` installed.
- **Android SDK** API 21 or higher.
- **Gradle 9.1.0**, **AGP 9.0.1**, **Kotlin 2.3.20**.

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
- Firebase project configuration is provided in `lib/firebase_options.dart` and `android/app/google-services.json` (Project ID: `customer-management-syst-36662`).
- Ensure **Email/Password** sign-in is enabled in **Firebase Console → Authentication → Sign-in method**.
- Firebase App Check is enabled with Play Integrity (release) and Debug Provider (debug).

### 4. Deploy Firestore Security Rules
Deploy the provided security rules to your Firebase project:
```bash
firebase deploy --only firestore:rules
```
*(No Cloud Functions or paid Blaze plan required — runs 100% on Firebase Spark free tier).*

### 5. Running the Application & First-Time Setup
1. Launch the app on an Android device or emulator:
   ```bash
   flutter run
   ```
2. On first launch on the login screen, tap **"First time? Create the Admin account"**.
3. Fill in the branch manager details (Name, Email, Phone, Password). This creates the branch Admin account and locks the bootstrap path.
4. Log in as Admin to manage customers, add staff, or export records.

---

## Running Unit & Widget Tests

Execute all test suites with:
```bash
flutter test
```
The test suite (29 tests) covers:
- `test/validators_test.dart` — Form input validation rules (Pakistani phone, CNIC, account numbers, IBAN, account title).
- `test/customer_model_test.dart` — Field masking, last-4 digit extraction, search keyword generation, and serialization.
- `test/user_model_test.dart` — Role-based permission checks (`isAdmin` vs staff permissions).
- `test/widget_test.dart` — Login screen UI rendering and auth state gating smoke test.

---

## Key Architecture & Design Decisions

- **Cybersecurity Defense-in-Depth**: Combines root detection, hardware attestation via Play Integrity App Check, `FLAG_SECURE` OS window shielding, session timeouts, and client rate limiting.
- **View-Only Context Isolation**: Searching or browsing recent customers on the Dashboard opens customer profiles in strict view-only mode (`allowEditAction: false`). Only the dedicated Customer Management workflow allows editing, eliminating accidental modifications.
- **Secondary Firebase App Instance for Staff Creation**: `AuthService.createStaffAccount` creates new staff credentials on a temporary secondary `FirebaseApp` instance. This prevents Firebase Auth from automatically swapping out Admin's active session on the primary app instance while staying on the free Spark plan without requiring Cloud Functions.
- **Field-Isolated Search**: Searches are executed against single dedicated fields (`phoneLast4`, `cnicLast4`, `accountNumberLast4`, `accountTitleSearchWords`) rather than a single combined array, preventing false positive cross-field matches.
- **Biometric App Lock**: Biometric verification is implemented as an on-device circular vault gate in front of an already persisted Firebase Auth session. It does not store plaintext or encrypted user passwords.
- **Account Number Immutability**: Account Numbers serve as Firestore document IDs and cannot be edited after creation, preserving audit trail integrity in `activityLog`.
