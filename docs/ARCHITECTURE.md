# ARCHITECTURE — CMS

## Folder structure

```
lib/
  main.dart                     # entry point, App Check, integrity guard, auth-state routing
  firebase_options.dart
  core/
    theme/app_theme.dart        # brand colors, global widget theming
    utils/
      validators.dart           # Pakistani-format field validation (phone, CNIC, account, IBAN)
      device_integrity_service.dart # root, jailbreak, Frida/Xposed hooks detection
      login_rate_limiter.dart   # 5-attempt rate limiter with 30s lockout countdown
      perspective_page_route.dart # 3D screen-transition route
    widgets/                    # reusable, cross-screen components:
      section_card.dart, account_field.dart, primary_button.dart,
      feedback_text.dart, tilt_tap_card.dart, fade_in_slide.dart,
      shimmer_loading.dart, biometric_lock_screen.dart,
      dashboard_stat_card.dart, error_state.dart, inactivity_watcher.dart
  data/
    models/                     # AppUser, Customer, ActivityLogEntry
    services/                   # AuthService, CustomerService,
                                # StaffService, ActivityService,
                                # ExportService, BiometricService
  modules/
    authentication/views/       # Login, Create Admin (first-run)
    home/views/                 # Dashboard, Staff mgmt, Staff profile,
                                # Add staff, Activity log
    customers/views/            # Add customer, Customer details/edit,
                                # Customer management, Search-by-field,
                                # Search results
    profile/views/              # Edit own account (My Account)
  routes/app_routes.dart
android/                        # Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, FLAG_SECURE, allowBackup=false
firestore.rules
assets/icon/                    # app_logo.png
tools/create_first_admin.js     # backup path for seeding an Admin
docs/                           # documentation suite
test/                           # 39 unit and widget tests (100% passing)
```

## Firestore data model

Five collections:

- **`users/{uid}`** — one doc per login (Admin or Staff), keyed by
  Firebase Auth UID. Fields: `name`, `email`, `phone`, `isAdmin`,
  `permissions {view,add,edit,delete}`, `active`, `createdBy`,
  `createdAt`.
- **`customers/{accountNumber}`** — doc ID **is** the account number
  (guarantees no duplicate account numbers structurally, no extra
  lookup needed). Fields: `name`, `accountTitle`, `phone`, `cnic`,
  `accountType`, `ibnNo`, `gender`, `status`, `email`, `dateOpened`,
  `address`, `notes`, `searchKeywords`, `phoneLast4`, `cnicLast4`,
  `accountNumberLast4`, `accountTitleSearchWords`, `createdBy/At`, `updatedBy/At`.
- **`activityLog`** — append-only. Nothing is ever updated or deleted
  here, including by Admin (enforced by rules) — that's what makes it
  trustworthy as an audit trail.
- **`phoneIndex/{normalizedPhone}`** — `{email, uid}`. Locked behind
  `signedIn()` in `firestore.rules` to prevent unauthenticated enumeration.
  Used to resolve a phone-number login to the account's real email.
- **`system/bootstrap`** — single doc, `{adminExists: bool}`. Gates the
  one-time self-serve Admin creation flow.

### Search — field-isolated, never global

The Dashboard search bar is a tap-trigger (read-only field) that opens
`SearchCustomerScreen`. The user must pick exactly ONE field — Account
Title, Account Number, Phone, or CNIC — before entering a value.
`SearchResultsScreen` *requires* a `CustomerSearchField`, so it cannot be
reached without one, and calls `CustomerService.searchByField`, which
dispatches to one of four methods that each query exactly one field:

| Search by      | Input            | Firestore query                                  |
|----------------|------------------|--------------------------------------------------|
| Account Title  | free text (2+ letters in at least one word) | `accountTitleSearchWords` array-contains-any, then narrowed client-side to titles containing every typed word |
| Phone          | exactly 4 digits | `phoneLast4 ==`                                  |
| CNIC           | exactly 4 digits | `cnicLast4 ==`                                   |
| Account Number | exactly 4 digits | `accountNumberLast4 ==`                          |

`phoneLast4`, `cnicLast4`, `accountNumberLast4` and
`accountTitleSearchWords` are written by `Customer.toMap()` on every add
and edit.

**Existing customers need a one-time backfill.** Admin runs "Sync search index"
in the drawer (`CustomerService.backfillSearchFields`) once; it is idempotent.

### Dashboard statistics & Recent Customers

Total Customers and New This Month use Firestore `count()` aggregation
queries (no documents downloaded). The growth chart is a fixed last-7-days
view built from per-day counts. Recent customer cards prominently display
`accountTitle` as the primary heading (above `accountNumber` and masked
phone/CNIC).

### View-Only vs Editable Context Isolation

To eliminate accidental customer modification during routine lookup:
- **Dashboard recent cards** and **Search Results** open `CustomerDetailScreen`
  with `allowEditAction: false`. The screen renders fields in read-only mode,
  and the Edit button is completely suppressed.
- **Customer Management** (`CustomerManagementScreen`) is the dedicated
  administrative hub for customer operations and opens `CustomerDetailScreen`
  with `allowEditAction: true` (subject to the user's `can('edit')` permission).

## Cybersecurity Architecture

The application adopts a defense-in-depth model across device, network,
application, and database layers:

1. **Hardware & Environment Attestation**:
   - `DeviceIntegrityService` checks on launch whether the device is rooted,
     jailbroken, running under an untrusted emulator, or hooked by binary
     instrumentation frameworks (Frida, Xposed). If compromised, the app halts
     at an enforced Security Alert screen, refusing all database/auth interactions.
2. **Backend API Attestation (Firebase App Check)**:
   - Initialized in `main.dart` with `AndroidPlayIntegrityProvider` (release)
     and `AndroidDebugProvider` (debug). Ensures only genuine, un-tampered
     app binaries can query Firebase services.
3. **OS-Level Window Privacy (`FLAG_SECURE`)**:
   - Enabled in `MainActivity.kt`. Blocks screen recordings, screenshots,
     and masks the app window in Android's recent apps switcher.
4. **Brute-Force Attack Mitigation**:
   - `LoginRateLimiter` enforces a 30-second lockout after 5 consecutive failed
     login attempts, displaying a live countdown in `LoginScreen`.
5. **Inactivity Session Auto-Lock**:
   - `InactivityWatcher` wraps the authenticated UI tree. Any continuous 5-minute
     span without touch or gesture events automatically triggers `signOut()`.
6. **Phone Index Protection**:
   - `firestore.rules` restricts `/phoneIndex/{phone}` access to authenticated
     sessions (`signedIn()`), closing enumeration loopholes.
7. **Responsive Font Scaling Guard**:
   - In `main.dart`, `MaterialApp.builder` clamps `textScaler` between `0.85`
     and `1.15`, maintaining accessibility compliance while preventing severe
     UI overflow and text clipping on extreme OS font settings.

## Auth — the tricky parts, and why

**Every account has a real, mandatory email AND phone.** Email is the
actual Firebase Auth identity. Phone-number login works by looking up
`phoneIndex` to resolve the real email, THEN signing in normally.

**Creating a staff account without logging Admin out of their own session.**
`AuthService.createStaffAccount` creates the new Auth user on a
**temporary, second Firebase app instance** (`Firebase.initializeApp(name:
..., options: DefaultFirebaseOptions.currentPlatform)`), which is
immediately torn down after. The Firestore writes for the new
user/phoneIndex/activityLog docs happen on the *default* app, under
Admin's still-valid session. Stays 100% on the free Spark tier without Cloud Functions.

**Email changes** use Firebase's verify-then-sync flow, not the
deprecated direct `updateEmail()`: `requestEmailChange()` re-authenticates
with the current password, then calls `verifyBeforeUpdateEmail(newEmail)`.
`confirmEmailChangeIfVerified()` updates Firestore's `users.email` and
`phoneIndex` only after verified reload.

## Biometric vault — app-lock, not password replacement

Biometric does **not** store a password anywhere, ever. Firebase Auth
already persists a session across app restarts on its own. Biometrics is a
circular vault gate in front of that already-valid session.
Enabled/disabled state is stored **per-uid** (`biometric_lock_enabled_<uid>`
in `flutter_secure_storage`). A `NotEnrolled` platform error auto-disables
the stored flag, forcing re-enable rather than leaving a dead lock.

## Firestore Security Rules — the actual enforcement layer

`firestore.rules` re-checks everything the app's UI already checks.
Key points: `isAdmin()`/`isActive()`/`can(perm)` helpers read the
CALLER's own `users/{uid}` doc; `activityLog` blocks all update/delete
unconditionally; a user can update their own `users` doc's basic fields
but never their own `isAdmin`/`permissions`/`active`; the very first
Admin can create their own doc only while `system/bootstrap.adminExists
== false`.

**Whenever `firestore.rules` changes, it must be redeployed**
(`firebase deploy --only firestore:rules` or paste into Firebase
Console → Firestore → Rules → Publish).
