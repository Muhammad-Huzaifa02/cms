# CMS — Customer Management System

Internal branch tool for **Meezan Bank**. Independent customer lookup and record management tool — not connected to core banking systems.

---

## Features

- **Dual Authentication (Email OR Phone)**: Sign in with either a verified email or Pakistani mobile number (`03xx-xxxxxxx`) and password.
- **First-Time Self-Serve Admin Bootstrap**: First-run setup directly inside the app to create the branch manager (Admin) account without Firebase console steps.
- **Staff Account Management**: Admin can create staff accounts and assign individual permissions (`view`, `add`, `edit`, `delete`) and toggle account active/deactivated status.
- **Customer Record CRUD**: Full customer management with strict Pakistani mobile (`03xx-xxxxxxx`), CNIC (13 digits), and Account Number (14 digits) format validations and duplicate checks.
- **Field-Isolated Search**: Search customers strictly by exact fields (`Account Title`, `Account Number`, `Phone`, or `CNIC`) with 4-digit last-four lookup and dedicated index backfill.
- **Data Masking & Security**: CNIC, Account Number, and Phone masked by default (showing last 4 digits) with tap-to-reveal.
- **Biometric App-Lock**: Optional fingerprint / Face ID session lock isolated per user UID without storing passwords.
- **Excel & PDF Export**: Admin-only customer list export with OS native sharing and audit logging.
- **Append-Only Activity Audit Log**: Every customer addition, update, deletion, staff permission change, and export is logged in an append-only audit trail.

---

## Project Structure

```
lib/
  main.dart                  # Application entry point, auth gate & lock gate
  firebase_options.dart      # Firebase SDK options
  core/                      # Shared theme, validators, and UI components
    theme/app_theme.dart     # Brand color palette and global widget styling
    utils/validators.dart    # Strict Pakistani format validators (phone, CNIC, account)
    widgets/                 # Reusable UI components (SectionCard, PrimaryButton, etc.)
  data/
    models/                  # AppUser, Customer, ActivityLogEntry
    services/                # AuthService, CustomerService, StaffService, ActivityService, ExportService, BiometricService
  modules/
    authentication/views/    # LoginScreen, CreateAdminScreen
    home/views/              # DashboardScreen, StaffManagementScreen, AddStaffScreen, ActivityLogScreen
    customers/views/         # AddCustomerScreen, CustomerDetailScreen, SearchCustomerScreen, SearchResultsScreen
    profile/views/           # EditProfileScreen (My Account)
  routes/app_routes.dart     # Central route definitions
firestore.rules              # Security rules for Cloud Firestore
test/                        # Unit and widget test suite
```

---

## Getting Started

### 1. Prerequisites
- **Flutter SDK** `>=3.3.0 <4.0.0` installed.
- **Android SDK** API 21 or higher.

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
- Firebase project configuration is provided in `lib/firebase_options.dart` and `android/app/google-services.json` (Project ID: `customer-management-syst-36662`).
- Ensure **Email/Password** sign-in is enabled in **Firebase Console → Authentication → Sign-in method**.

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
The test suite covers:
- `test/validators_test.dart` — Form input validation rules (Pakistani phone, CNIC, account numbers, account title).
- `test/customer_model_test.dart` — Field masking, last-4 digit extraction, and search keyword generation.
- `test/user_model_test.dart` — Role-based permission checks (`isAdmin` vs staff permissions).
- `test/widget_test.dart` — Login screen UI rendering smoke test.

---

## Key Architecture & Design Decisions

- **Secondary Firebase App Instance for Staff Creation**: `AuthService.createStaffAccount` creates new staff credentials on a temporary secondary `FirebaseApp` instance. This prevents Firebase Auth from automatically swapping out Admin's active session on the primary app instance while staying on the free Spark plan without requiring Cloud Functions.
- **Field-Isolated Search**: Searches are executed against single dedicated fields (`phoneLast4`, `cnicLast4`, `accountNumberLast4`, `accountTitleSearchWords`) rather than a single combined array, preventing false positive cross-field matches.
- **Biometric App Lock**: Biometric verification is implemented as an on-device session gate in front of an already persisted Firebase Auth session. It does not store plaintext or encrypted user passwords.
- **Account Number Immutability**: Account Numbers serve as Firestore document IDs and cannot be edited after creation, preserving audit trail integrity in `activityLog`.
