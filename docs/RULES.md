# RULES — conventions any change to this project must follow

## Validation (strict Pakistani formats — do not loosen these)

All field formats live in `core/utils/validators.dart` as the single source of
truth. Customer forms AND Staff forms must use the same `Validators`
class — do not write a second, slightly-different check somewhere else.

- **Phone**: exactly 11 digits, digits only, must start with `03`.
  Error: *"Phone number must be a valid Pakistani mobile number with
  exactly 11 digits."*
- **CNIC**: exactly 13 digits, digits only, no dashes/spaces. Do not
  silently strip separators the user typed — reject with the message,
  don't "fix" it for them. Error: *"CNIC must contain exactly 13
  digits."*
- **Account Number**: exactly 14 digits, digits only. Error: *"Account
  number must contain exactly 14 digits."*
- **IBAN (IBN No.)**: exactly 24 characters, must start with `PK`,
  alphanumeric uppercase. Placed directly after Account Number in forms.
  Error: *"IBAN must be exactly 24 characters and start with PK."*
- **Account Title**: required, must contain at least one letter (not
  purely numeric/symbols). Error: *"Account Title is required."*

Apply input formatters too (`FilteringTextInputFormatter.digitsOnly` +
`LengthLimitingTextInputFormatter`), not just validators — both layers,
always, on every form that collects these fields.

## Duplicates

Adding or editing a customer must check for an existing customer with
the same phone or CNIC (`CustomerService.findByPhone`/`findByCnic`) and
reject with a clear message naming the conflicting customer. On edit,
only check fields that actually *changed* (compare against
`originalPhone`/`originalCnic`) — don't flag a customer's own unchanged
value as a duplicate of itself.

## Search & Navigation — view-only vs edit gating is a hard rule

- **User-facing customer search** must only ever query the single field the
  user picked (Account Title, Account Number, Phone, or CNIC). Never add a
  "search everything" box and never route user search through the shared
  `searchKeywords` array.
- **View-Only from Search & Dashboard**: Opening customer details from Search
  Results or Dashboard Recent Customer cards must pass `allowEditAction: false`.
  The Edit action must never be exposed from these lookup paths.
- **Editing is restricted to Customer Management**: Only `CustomerManagementScreen`
  supplies `allowEditAction: true` to `CustomerDetailScreen`, ensuring intentional,
  permission-checked customer modifications.

## Data integrity

- **Account Number is never editable after creation.** It's the
  Firestore document ID. "Changing" it would mean delete-old-doc +
  create-new-doc, which orphans every `activityLog` entry that
  references the old ID.
- **`activityLog` is append-only.** Never add an update or delete path
  for it, in code or in rules, for any reason, including for Admin.
- **CNIC, Account Number, and Phone are masked (last 4 digits) by default**
  everywhere they're displayed — detail screens, search results,
  recent-customer lists. Reveal is an explicit tap, never automatic.

## Cybersecurity Hardening

- **Device Integrity Guard**: The app must fail closed if rooted, jailbroken,
  or hooked. Do not bypass or remove `DeviceIntegrityService` checks.
- **Window Privacy Protection**: `FLAG_SECURE` in `MainActivity.kt` must remain
  active to block screen capture, malware video recording, and OS app switcher caching.
- **Session Auto-Lock**: `InactivityWatcher` must wrap authenticated sessions with
  a 5-minute timeout.
- **Brute-Force Rate Limiting**: `LoginRateLimiter` must enforce a 30-second lockout
  after 5 failed credential submissions.
- **Phone Index Security**: `/phoneIndex` reads must remain restricted to authenticated
  users (`signedIn()`) in `firestore.rules` to prevent unauthenticated enumeration.
- **Never store a password anywhere** except transiently in memory to
  send to Firebase Auth. This includes biometric login.
- Every permission check in the UI (`AppUser.can('edit')` etc.) must
  have a matching, independent check in `firestore.rules`.
- Firebase project stays on the **free Spark plan** — no Cloud
  Functions, no feature that requires the Blaze plan.

## Process & UI Consistency

- **Responsive Font Scale Clamping**: Global `textScaler` in `MaterialApp.builder`
  must remain clamped to `0.85–1.15` to ensure UI stability across devices.
- Don't downgrade Flutter, Gradle, the Android Gradle Plugin, or
  Kotlin. Keep modern toolchain versions (Gradle 9.1.0+, AGP 9.0.1+, Kotlin 2.3.20+).
- Always clean up asynchronous timers (`Timer.cancel()`) on widget disposal
  (e.g., in `FadeInSlide` or `InactivityWatcher`) to prevent memory leaks and flaky test runs.
- `firestore.rules` changes require a deploy to take effect. Say so
  explicitly whenever the rules file changes.
