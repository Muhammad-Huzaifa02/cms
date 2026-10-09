# TASKS — status

## Done

- [x] Auth: email OR phone + password login, both mandatory on every
      account, phone resolved via `phoneIndex`.
- [x] Self-serve Admin bootstrap (one-time, in-app, no console step).
- [x] Staff accounts: Admin creates them, sets individual
      view/add/edit/delete permissions, can deactivate.
- [x] Staff creation doesn't disturb Admin's own session (secondary
      Firebase app instance — no Cloud Functions, stays free-tier).
- [x] Customer CRUD: Add/Edit with Account Title, strict Pakistani
      phone/CNIC/account-number validation, duplicate phone/CNIC
      detection.
- [x] Search: field-isolated — pick Account Title / Account Number /
      Phone / CNIC, then enter a value (exactly 4 digits for the three
      numeric fields, 2+ letters for title). Result cards show Account
      Title plus all three masked identifiers.
- [x] "Sync search index" (Admin, drawer) backfills the new search
      fields for customers saved before field-isolated search existed.
- [x] Dashboard: Total Customers, New This Month, 7-day growth chart,
      Admin quick actions, skeleton loading, and error-with-retry states.
- [x] Customer Details and Add Customer use the same sectioned layout
      and shared components as My Account.
- [x] CNIC/Account Number masked by default, tap-to-reveal.
- [x] Activity log — append-only, Admin-only visibility.
- [x] Export to Excel/PDF (Admin-only), logged to activity log.
- [x] My Account: edit own name/phone, change password, change login
      email (verify-then-sync flow), biometric app-lock toggle.
- [x] Biometric app-lock: manual-tap only, per-uid isolation, no stored
      password, enrollment-change detection, full error-state coverage.
- [x] `core/`/`data/`/`modules/`/`routes/` architecture.
- [x] Reusable UI kit: SectionCard, AccountField, PrimaryButton,
      FeedbackText, TiltTapCard, FadeInSlide, Perspective3DRoute,
      ShimmerLoading.
- [x] App logo + launcher icon source.
- [x] Real Firebase project wired for Android
      (`customer-management-syst-36662`).

## Known limitations / deliberately not done

- **Customers saved before field-isolated search won't appear in field
  search until the Admin runs "Sync search index" once** (drawer →
  Sync search index). New and edited customers are indexed automatically.
- **No floating bottom-navigation dock and no blue palette** — a
  deliberate scope decision, see MEMORY.md.
- **No Active/Inactive customer stats** — the field doesn't exist.
- **Account Title search reads up to 50 candidate documents** before
  narrowing client-side; a very common title prefix with more than 50
  matches could hide some. Fine for one branch's size; revisit if it grows.

- **Account Number is not editable** after a customer is created — it's
  the Firestore document ID; changing it would orphan activity-log
  history. See RULES.md. Revisit only as a deliberate, separately-
  designed feature if actually needed.
- **iOS Firebase config** has not been set up — only Android
  (`google-services.json`) is confirmed wired. Run `flutterfire
  configure` and select iOS when ready to build for iPhone.
- **No automated test coverage** beyond one smoke test
  (`test/widget_test.dart`) verifying the Login screen renders with
  injectable `AuthService`/mocks.
- **Claude cannot run `flutter analyze` / `flutter build` /
  `flutter test`** in the sandbox used to develop this (no Flutter SDK
  installed there) — every change has been verified by brace/paren
  balance checks and manual cross-reference only. **Always run the real
  toolchain locally after any AI-assisted change** before trusting it.
- **Export** produces a local Excel/PDF file and hands it to the OS
  share sheet — there's no cloud backup/archival of exports.

## Next candidates (not started)

- Data retention / archival policy for closed accounts.
- A "recently deleted" trash/undo window for customer deletion.
- Pagination on the Dashboard's recent-customers list (currently
  capped at a fixed `limit`).
