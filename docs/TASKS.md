# TASKS — status

## Done

- [x] Auth: email OR phone + password login, both mandatory on every
      account, phone resolved via `phoneIndex`.
- [x] Loophole #2 remediation: `/phoneIndex/{phone}` locked to authenticated
      users (`signedIn()`) to block unauthenticated enumeration.
- [x] Cybersecurity defense suite:
      - Device Integrity Service (detects root, jailbreak, Frida/Xposed hooks, emulator tampering).
      - Firebase App Check (Play Integrity on release, Debug Provider on debug).
      - Android `FLAG_SECURE` window protection (screenshot, video capture & task switcher masking).
      - Brute-force rate limiter (5 failed attempts trigger 30s lockout countdown).
      - Inactivity session auto-lock (5 minutes of idle time auto-signs out).
- [x] Self-serve Admin bootstrap (one-time, in-app, no console step).
- [x] Staff accounts: Admin creates them, sets individual
      view/add/edit/delete permissions, can deactivate.
- [x] Staff profile screen: Tapping any staff card in Staff Management
      opens a dedicated `StaffProfileScreen` for detail inspection and live
      permission toggles.
- [x] Staff creation doesn't disturb Admin's own session (secondary
      Firebase app instance — no Cloud Functions, stays free-tier).
- [x] Customer CRUD: Add/Edit with Account Title, strict Pakistani
      phone/CNIC/account-number validation, duplicate phone/CNIC
      detection.
- [x] Full customer banking fields added:
      - IBAN (`PK...`, 24 characters, placed directly after Account Number).
      - Gender (`Male`, `Female`, `Other`).
      - Account Status (`Active`, `Inactive`, `Dormant`, `Blocked`).
      - Customer Email (optional).
- [x] View-only mode protection: Customer details opened from Dashboard recent cards
      or Search Results are strictly view-only (`allowEditAction: false`).
      Editing customer records is strictly permitted when navigating via Customer Management.
- [x] Search: field-isolated — pick Account Title / Account Number /
      Phone / CNIC, then enter a value (exactly 4 digits for the three
      numeric fields, 2+ letters for title). Result cards show Account
      Title plus all three masked identifiers.
- [x] "Sync search index" (Admin, drawer) backfills the new search
      fields for customers saved before field-isolated search existed.
- [x] Dashboard: Total Customers, New This Month count cards,
      Admin quick actions, skeleton loading, and error-with-retry states (Growth Trend Chart removed per design).
- [x] Dashboard recent customer cards display Account Title as the primary heading.
- [x] Dashboard UI design enhancements:
      - Native pull-to-refresh (`RefreshIndicator`) for stats and recent customer streams.
      - Redesigned executive banking header: Clean gradient backdrop (watermark removed), User avatar circle with dynamic gradient, time-aware greeting ("Good Morning/Afternoon/Evening"), prominent user name, and polished role badge (`ADMIN` gold vs `STAFF` badge pill).
      - Removed Today's Date Banner from header for a clean, focused executive layout.
      - "RECENT CUSTOMERS" section header with intake count badge and direct "View All →" link to Customer Management.
      - Customer card status indicator with colored dot (`Active`, `Dormant`, `Blocked`, `Inactive`).
      - Dual identifier preview on cards (masked account number `•` masked phone).
      - Account-type dynamic gradient avatars (`Savings`, `Current`, `Business`).
- [x] Customer Details and Add Customer use the standardized 9-field sequence:
      1. Account Title, 2. Account Number, 3. IBAN No, 4. Account Type, 5. Account Status, 6. CNIC, 7. Phone Number, 8. Email, 9. Address.
- [x] Unlocked customer editing: Account Number and Account Type (Category & Type selectors) fully editable in Edit Customer screen.
- [x] Upgraded Staff Management:
      - Real-time search across staff name, email, and phone number.
      - Status filter chips (All, Active, Deactivated) with live counter badges.
      - Fixed right RenderFlex overflow in staff cards by constraining flex rows and using vertical permission wrapping.
      - Redesigned Staff Profile screen with role presets, granular permission cards, active switch, and 1-tap contact copy.
- [x] Executive Banking Navigation Drawer overhaul:
      - Gradient executive header with bank badge ("CUSTOMER MANAGEMENT SYSTEM"), dynamic gradient avatar, user name, email/phone, role pill, and 1-tap navigation directly to Edit Profile.
      - Streamlined `OVERVIEW` section featuring Dashboard and Customer Management (removed redundant Add New Customer & My Profile items per spec).
      - Categorized administrative sections (`ADMINISTRATION`, `DATA & EXPORT`, `SYSTEM MAINTENANCE`).
      - Rounded navigation tiles with soft brand accent backgrounds, custom icon badges, descriptive subtitles, and active selection indicators.
      - Edge-to-edge safe bottom footer with prominent styled Sign Out button and secured portal build stamp.
- [x] Standardized font scaling: `TextScaler.noScaling` (1.0) applied globally to auto-normalize UI typography across all mobile devices regardless of OS font size settings.
- [x] High-readability customer view mode:
      - Crystal-clear typography and high-contrast ink (`AppColors.ink`) replacing faint muted text in read-only states.
      - Compact Hero Profile Header Card with dynamic account-type gradient avatar, large Account Title, real-time status pill, and account type badge (removed redundant quick copy buttons row to maximize vertical screen efficiency).
      - Distinct `_DetailFieldTile` design with 1-tap clipboard copy across all 9 individual fields.
- [x] Customer Management & Search Results card clarity:
      - Prominent Account Title heading with high-contrast text.
      - Account-type gradient avatar with bold initials.
      - Inline status indicator dot (`Active`, `Dormant`, `Blocked`, `Inactive`) and secondary identifier preview.
- [x] Streamlined customer records: Removed Customer Full Name and Notes from both Add Customer and Customer Details screens (Full Name mapped cleanly to Account Title).
- [x] CNIC/Account Number/Phone masked by default, tap-to-reveal.
- [x] Activity log — append-only, Admin-only visibility.
- [x] Export to Excel/PDF (Admin-only), updated with IBAN, Account Title, Gender,
      Status, and Email, logged to activity log.
- [x] My Account: edit own name/phone, change password, change login
      email (verify-then-sync flow), biometric app-lock toggle.
- [x] Redesigned biometric app-lock & session lock architecture:
      - Automatic prompt: Automatically initiates biometric authentication prompt on app launch and upon returning from background.
      - Responsive inactivity re-lock: `BiometricLockScreen` handles live inactivity timeout events via `didUpdateWidget`, re-locking and prompting immediately.
      - `onUnlocked` callback: Resets `_timedOut` state back to `false` in `_LockGate` upon successful authentication so sessions resume seamlessly.
      - Lifecycle awareness: Seamlessly re-locks on `paused` (backgrounded) and re-prompts on `resumed` without false triggers during native biometric sheets.
      - Executive Vault UI: Midnight banking gradient (`#011814`), bank branding badge, glowing concentric biometric sensor hub, dynamic status banners, primary unlock button, and password fallback signout.
      - Expanded unit/widget tests in `test/biometric_lock_screen_test.dart` (32/32 tests passing).
- [x] Responsive font scale clamping (`textScaler.clamp(0.85, 1.15)`) in
      `MaterialApp.builder` to preserve layouts on high accessibility font settings.
- [x] Modern build toolchain upgrade: Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20.
- [x] Lifecycle timer cleanup in `FadeInSlide` to prevent memory leaks and unhandled timer exceptions.
- [x] `core/`/`data/`/`modules/`/`routes/` architecture.
- [x] Reusable UI kit: SectionCard, AccountField, PrimaryButton,
      FeedbackText, TiltTapCard, FadeInSlide, Perspective3DRoute,
      ShimmerLoading, InactivityWatcher, BiometricLockScreen.
- [x] App logo + launcher icon source.
- [x] Real Firebase project wired for Android
      (`customer-management-syst-36662`).
- [x] Unit & widget test suite added (`validators_test.dart`, `customer_model_test.dart`,
      `user_model_test.dart`, `widget_test.dart`) — 29/29 tests (100%) passing.
- [x] Cleaned up unused files (`floating_navigation_bar.dart`,
      `premium_3d_card.dart`, `dashboard_stats_model.dart`).

## Known limitations / deliberately not done

- **Customers saved before field-isolated search won't appear in field
  search until the Admin runs "Sync search index" once** (drawer →
  Sync search index). New and edited customers are indexed automatically.
- **No floating bottom-navigation dock and no blue palette** — a
  deliberate scope decision, see MEMORY.md.
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
- **Export** produces a local Excel/PDF file and hands it to the OS
  share sheet — there's no cloud backup/archival of exports.

## Next candidates (not started)

- Data retention / archival policy for closed accounts.
- A "recently deleted" trash/undo window for customer deletion.
- Pagination on the Dashboard's recent-customers list (currently
  capped at a fixed `limit`).
