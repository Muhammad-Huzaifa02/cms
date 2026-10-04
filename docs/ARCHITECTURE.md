# ARCHITECTURE — CMS

## Folder structure

```
lib/
  main.dart                     # entry point, auth-state routing
  firebase_options.dart
  core/
    theme/app_theme.dart        # brand colors, global widget theming
    utils/
      validators.dart           # Pakistani-format field validation
      perspective_page_route.dart  # 3D screen-transition route
    widgets/                    # reusable, cross-screen components:
      section_card.dart, account_field.dart, primary_button.dart,
      feedback_text.dart, tilt_tap_card.dart, fade_in_slide.dart,
      shimmer_loading.dart, biometric_lock_screen.dart
  data/
    models/                     # AppUser, Customer, ActivityLogEntry
    services/                   # AuthService, CustomerService,
                                 # StaffService, ActivityService,
                                 # ExportService, BiometricService
  modules/
    authentication/views/       # Login, Create Admin (first-run)
    home/views/                 # Dashboard, Staff mgmt, Add staff,
                                 # Activity log
    customers/views/            # Add/Edit customer, Search results
    profile/views/              # Edit own account (My Account)
  routes/app_routes.dart
firestore.rules
assets/icon/                    # app_logo.png/.svg
tools/create_first_admin.js     # backup path for seeding an Admin
docs/                           # this folder
```

## Firestore data model

Four collections:

- **`users/{uid}`** — one doc per login (Admin or Staff), keyed by
  Firebase Auth UID. Fields: `name`, `email`, `phone`, `isAdmin`,
  `permissions {view,add,edit,delete}`, `active`, `createdBy`,
  `createdAt`.
- **`customers/{accountNumber}`** — doc ID **is** the account number
  (guarantees no duplicate account numbers structurally, no extra
  lookup needed). Fields: `name`, `accountTitle`, `phone`, `cnic`,
  `accountType`, `dateOpened`, `address`, `notes`, `searchKeywords`
  (see below), `createdBy/At`, `updatedBy/At`.
- **`activityLog`** — append-only. Nothing is ever updated or deleted
  here, including by Admin (enforced by rules) — that's what makes it
  trustworthy as an audit trail.
- **`phoneIndex/{normalizedPhone}`** — `{email, uid}`. Public-read,
  used to resolve a phone-number login to the account's real email
  before calling Firebase Auth (see "Auth" below).
- **`system/bootstrap`** — single doc, `{adminExists: bool}`. Gates the
  one-time self-serve Admin creation flow.

### Search

`Customer.buildSearchKeywords()` indexes: every prefix of every word in
`name` and `accountTitle`; every prefix AND suffix (from length 3–4 up)
of the cleaned (digits-only) `phone`, `cnic`, and `accountNumber`. This
is what makes "search last 4 digits of CNIC" or "search a partial name"
work via a single `array-contains` Firestore query, with a multi-word
fallback (`array-contains-any` + client-side narrowing) for queries like
an Account Title with spaces.

## Auth — the tricky parts, and why

**Every account has a real, mandatory email AND phone.** Email is the
actual Firebase Auth identity. Phone-number login works by looking up
`phoneIndex` to resolve the real email, THEN signing in normally — not
a "fake email" trick. Both are mandatory specifically so this always
resolves.

**Creating a staff account without logging Admin out of their own
session.** Firebase's client SDK signs you in as whichever account you
just created — calling `createUserWithEmailAndPassword` as Admin to
make a staff account would silently swap Admin's own session for the
new staff member's. Fixed by creating the new Auth user on a
**temporary, second Firebase app instance** (`Firebase.initializeApp(name:
..., options: DefaultFirebaseOptions.currentPlatform)`), which is
immediately torn down after. The Firestore writes for the new
user/phoneIndex/activityLog docs happen on the *default* app, under
Admin's still-valid session. See `AuthService.createStaffAccount`.

We deliberately do **not** use Cloud Functions for this (the "correct"
Admin-SDK-based fix) — Cloud Functions requires Firebase's Blaze
(pay-as-you-go) plan, which needs a billing card on file even to stay
within free quota. This project intentionally stays 100% free-tier.

**Email changes** use Firebase's verify-then-sync flow, not the
deprecated direct `updateEmail()`: `requestEmailChange()` re-authenticates
with the current password, then calls `verifyBeforeUpdateEmail(newEmail)`
— nothing in Firestore changes yet. `confirmEmailChangeIfVerified()` is
a separate, explicit step (a "sync now" button) that reloads the Auth
user and only then updates Firestore's `users.email` and `phoneIndex` —
this avoids ever having Firestore's copy of the email diverge from what
Firebase Auth actually has.

## Biometric login — app-lock, not password replacement

Biometric does **not** store a password anywhere, ever. Firebase Auth
already persists a session across app restarts on its own (unrelated to
biometrics). When enabled, biometrics is a manual-tap gate in front of
that already-valid session — see `BiometricLockScreen` /
`BiometricService`. Enabled/disabled state is stored **per-uid**
(`biometric_lock_enabled_<uid>` in `flutter_secure_storage`), not
globally — so multiple staff sharing one physical device don't inherit
each other's lock state. A `NotEnrolled` platform error (device's
fingerprint/Face ID enrollment changed) auto-disables the stored flag,
forcing re-enable rather than leaving a dead, un-satisfiable lock.

## Firestore Security Rules — the actual enforcement layer

`firestore.rules` re-checks everything the app's UI already checks,
because client-side permission checks are a UX nicety, not security.
Key points: `isAdmin()`/`isActive()`/`can(perm)` helpers read the
CALLER's own `users/{uid}` doc; `activityLog` blocks all update/delete
unconditionally; a user can update their own `users` doc's basic fields
but never their own `isAdmin`/`permissions`/`active`; the very first
Admin can create their own doc only while `system/bootstrap.adminExists
== false`.

**Whenever `firestore.rules` changes, it must be redeployed**
(`firebase deploy --only firestore:rules` or paste into Firebase
Console → Firestore → Rules → Publish) — editing the file locally does
nothing to the live project until deployed. This has caused real
`permission-denied` bugs in this project before.
