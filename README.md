# CMS — Customer Management System

Internal branch tool for Meezan Bank. Independent app — not connected to
core banking.

## Project layout

```
lib/
  main.dart                  # entry point, auth-state routing (always → Sign In when signed out)
  core/                      # theme, reusable widgets, page-transition utils
  data/
    models/                  # AppUser, Customer, ActivityLogEntry
    services/                # AuthService, CustomerService, StaffService,
                              # ActivityService, ExportService, BiometricService
  modules/
    authentication/views/    # Login, Create Admin (first-run setup)
    home/views/               # Dashboard, Staff management, Add staff, Activity log
    customers/views/          # Add/Edit customer, Search results
    profile/views/            # Edit own account
  routes/app_routes.dart
functions/                   # Cloud Function: server-side staff account creation
firestore.rules
assets/icon/                 # App logo (source + rasterized)
```

## First-time setup

1. **Flutter deps:**
   ```
   flutter pub get
   ```
2. **Firebase config** is already in `lib/firebase_options.dart` and
   `android/app/google-services.json` for project
   `customer-management-syst-36662`. If you ever repoint this to a
   different Firebase project, run `flutterfire configure` again.
3. **Enable Email/Password sign-in** — Firebase Console → Authentication →
   Sign-in method → Email/Password → Enable. (Everything authenticates via
   a real email under the hood, even phone-number logins — see
   `AuthService`'s doc comments.)
4. **Deploy Firestore rules:**
   ```
   firebase deploy --only firestore:rules
   ```
5. **Deploy the Cloud Function** (this is what lets Admin create staff
   accounts without getting logged out of their own session):
   ```
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```
   Without this deployed, "Add staff account" will fail — it calls the
   `createStaffAccount` callable function.
6. **Create the first Admin account** — open the app, tap **"First time?
   Create the Admin account"** on the Sign In screen. No console step
   needed; this is a one-time, self-closing path (see `/system/bootstrap`
   in `firestore.rules`).
7. **Run it:**
   ```
   flutter run
   ```

## Why a Cloud Function for staff creation?

Firebase's client SDK has a well-known quirk: calling
`createUserWithEmailAndPassword` signs you in as the account you just
created. That meant every time Admin added a staff member, Admin's own
session got silently swapped for the new staff member's — a real bug,
not just an inconvenience. `functions/index.js` creates the account
server-side via the Admin SDK instead, which never touches the caller's
client session. The function itself re-checks that the caller is an
active Admin before doing anything — client-side checks are a UX nicety,
this is the actual enforcement.

## Known design choices worth knowing

- **Email is mandatory on every account** and is the real Firebase Auth
  login. **Phone is also mandatory**, registered via a small public
  `phoneIndex/{normalizedPhone} → {email, uid}` lookup collection, so
  phone-number sign-in resolves to the real email before authenticating.
  Both were made mandatory specifically so this always works.
- **CNIC and account numbers are masked by default** in list/detail views
  (last 4 digits), with a tap-to-reveal.
- **Biometric login** stores the account's password in
  `flutter_secure_storage` (OS-level encrypted storage) to replay after a
  fingerprint/Face ID check — this works, but if you'd rather biometrics
  only gate access to an already-persisted Firebase session (no password
  storage at all), that's a reasonable alternative worth considering for
  a banking-adjacent tool.
- **Export (Excel/PDF) is Admin-only** and logs an `activityLog` entry
  each time.
- **Activity log is append-only** — even Admin can't edit or delete
  entries, by rule.
