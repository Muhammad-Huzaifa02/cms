# CMS — Customer Management System

Internal branch tool for Meezan Bank. Independent app — not connected to
core banking. Built from the SRS and Firestore Data Model documents.

## What's in this scaffold

```
lib/
  main.dart                     # entry point, auth-state routing
  firebase_options.dart         # PLACEHOLDER — replace via flutterfire configure
  theme/app_theme.dart          # brand colors, matches the UI concept docs
  models/
    user_model.dart             # Admin/Staff + per-user Permissions
    customer_model.dart         # customer record, masking, search keywords
    activity_log_model.dart     # audit trail entry
  services/
    auth_service.dart           # email OR phone + password login (FR-1.1)
    customer_service.dart       # CRUD + search, permission-checked
    staff_service.dart          # Admin-only staff management
    activity_service.dart       # append-only audit log
  screens/
    login_screen.dart
    dashboard_screen.dart       # search + recent customers
    search_results_screen.dart
    customer_detail_screen.dart # masked CNIC/account with Reveal
    add_customer_screen.dart
    staff_management_screen.dart
    add_staff_screen.dart
    activity_log_screen.dart    # Admin only
firestore.rules                 # server-side enforcement — see Data Model §5
pubspec.yaml
```

## Your Firebase project

`google-services.json` (Android) is already in `android/app/` and
`lib/firebase_options.dart` has been filled in with your real project
values (project: `customer-management-syst-36662`).

**One mismatch to fix:** your `google-services.json` registers package
name `com.example.cms`, but step 2 below (`flutter create --org
com.meezanbank`) would generate `com.meezanbank.cms`. Either:
- run `flutter create --org com.example cms_app` instead (package name
  matches what's already registered, zero extra steps), or
- keep `com.meezanbank`, then in Firebase Console → Project Settings,
  add a *second* Android app registered as `com.meezanbank.cms` and
  re-download `google-services.json`.
The first option is less work if this project ID is just for
development/testing.

No iOS config was provided — add that app in Firebase Console when
you're ready to build for iOS, download `GoogleService-Info.plist`, and
fill in the `ios` block in `firebase_options.dart` (or just re-run
`flutterfire configure`).

## First-time setup

1. **Install Flutter** (if not already): https://docs.flutter.dev/get-started/install
2. **Create the Flutter project shell:**
   ```
   flutter create --org com.example cms_app
   ```
   Then copy everything from this scaffold (`lib/`, `assets/`,
   `pubspec.yaml`, `firestore.rules`, `android/app/google-services.json`)
   into the generated project, overwriting the defaults.
3. **Enable Email/Password sign-in:** Firebase Console → Authentication →
   Sign-in method → enable "Email/Password". (Both the email-login and
   phone-login paths use this provider under the hood — see the note in
   `auth_service.dart`.)
4. **Deploy the security rules:**
   ```
   firebase deploy --only firestore:rules
   ```
5. **Generate the app icon:**
   ```
   flutter pub get
   dart run flutter_launcher_icons
   ```
   This turns `assets/icon/app_logo.png` into the real Android/iOS
   launcher icons.
6. **Create the first Admin account** — there is no default login, and
   now there's no console/script step needed either: open the app, and
   on the login screen tap **"First time? Create the Admin account"**.
   That link only appears when no Admin exists yet (checked via
   `/system/bootstrap` in Firestore) — the moment one is created, the
   link disappears for everyone else, permanently, enforced by
   `firestore.rules`. The Node script (`tools/create_first_admin.js`)
   still works too, as a backup path if you ever need to script it.

   Every account after this first one is created *from inside the app*
   by this Admin (Staff → Add staff account screen) — that's the whole
   point of the permission model.
7. **Run it:**
   ```
   flutter run
   ```

## What's new in this round

- **Fixed: `CONFIGURATION_NOT_FOUND` sign-in error** — this means
  Email/Password sign-in wasn't enabled in Firebase Console yet (see
  step 3 above). If you also saw a `firebase_auth/channel-error` before
  that, it means the app was hot-reloaded after adding `firebase_auth`
  instead of getting a full rebuild — run `flutter clean` then
  `flutter run` (cold build) whenever you add/change a Firebase package.
- **Self-service Admin bootstrap** — `create_admin_screen.dart` +
  `AuthService.bootstrapFirstAdmin` let the branch manager create their
  own Admin account from the app on first run, no console/script step
  needed. Guarded by `/system/bootstrap` in `firestore.rules` so it can
  only ever happen once.
- **Export wired up** — Dashboard's ⋮ menu (Admin only) has "Export to
  Excel" and "Export to PDF", both calling `ExportService` and sharing
  the generated file via the OS share sheet.
- **3D animations** — `utils/perspective_page_route.dart` gives every
  screen transition a real rotateY/perspective fly-in (matches the tilted
  phone mockups); `widgets/tilt_tap_card.dart` gives customer cards a
  physical press-down effect on tap; the login card has a one-time
  3D entrance animation on load.
- **App logo** — `assets/icon/app_logo.svg` (edit this, it's the source
  of truth) and the rasterized `app_logo.png` used both in the login
  screen and as the launcher icon source.

## Known scaffold shortcuts (flag before real deployment)

- `AuthService.createStaffAccount` calls `createUserWithEmailAndPassword`
  directly from the client, which signs the Admin out of their own
  session as a side effect of Firebase Auth's client SDK. For production,
  move this to a Cloud Function using the Admin SDK so creating staff
  doesn't disrupt the Admin's session.
- Export (FR-2.6, Excel/PDF) is scaffolded as a dependency
  (`excel`, `pdf` packages) but the actual export screen/button isn't
  wired up yet — straightforward to add on top of `CustomerService`.
- Phone+password login uses a synthetic-email workaround (see comment in
  `auth_service.dart`) since Firebase's native phone provider is OTP-only.
  This is a common, safe pattern, but worth knowing it's there.
