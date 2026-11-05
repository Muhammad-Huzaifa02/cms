# PRD — CMS (Customer Management System)

## What this is

A branch management tool. A branch manager (Admin) and
their staff use it to look up, add, and edit customer contact/identity
records — name, Account Title, phone, CNIC, account number, IBAN, account
type, gender, account status, email, address, and notes. It is **independent of core banking**: no real-time connection to
transaction systems, no balances, no transfers. It exists to answer one
question fast: "who is this customer, and what's their account number?"

## Users

- **Admin** — the branch manager. Exactly one exists per deployment,
  created via a one-time in-app self-setup flow (no console/script
  step). Full access to everything, always.
- **Staff** — created only by Admin, from inside the app. Each staff
  account has its own, individually-assigned permissions: `view`,
  `add`, `edit`, `delete` — no fixed role names like "Editor" or
  "Viewer". Admin can grant any combination per person, view staff profiles, and toggle active status.

There is no self-registration. Nobody creates their own account except
Admin, once, on first run.

## Core functional requirements

- **Login & Authentication**: email OR phone number, both with a password.
  Secured with brute-force rate limiting (5 failed attempts trigger a 30s lockout).
- **Search**: by Account Title, phone, CNIC, or account number —
  exact field match or last-4-digits partial match on the numeric fields.
  Results are opened in **view-only** mode to prevent accidental edits during lookups.
- **Add/Edit customer**: Full Name, Account Title, Phone, CNIC, Account
  Number, IBAN (`PK...`, 24 chars), Gender (`Male`, `Female`, `Other`), Account Status (`Active`, `Inactive`, `Dormant`, `Blocked`), Account Type, Email, Address, Notes. Strict Pakistani-format
  validation on Phone/CNIC/Account Number/IBAN (see RULES.md). Duplicate
  Phone/CNIC rejected with a clear message.
- **Controlled Edit Access**: Editing customer records is strictly permitted when
  navigating through the dedicated Customer Management workflow (`allowEditAction: true`).
  Dashboard recent cards and Search Results remain strictly view-only.
- **Dashboard**: Displays recent customers with Account Title as primary heading,
  account number, and masked identifiers.
- **Masking**: CNIC, Account Number, and Phone are masked (last 4 digits shown)
  everywhere by default, with tap-to-reveal.
- **Staff management**: Admin creates staff accounts, views staff profiles, and sets each
  one's permissions; can toggle active/inactive at any time.
- **Activity log**: append-only audit trail (who added/edited/deleted
  what, and staff/permission changes), visible to Admin only.
- **Export**: Admin-only, to Excel or PDF (including Account Title, IBAN, Gender, Status, Email), logged to the activity log.
- **My Account**: any signed-in user can edit their own name and phone,
  change their password, change their login email (with real
  verification), and enable/disable a biometric vault app-lock.
- **Cybersecurity Hardening**:
  - Device integrity checks (root / jailbreak / hook detection).
  - Play Integrity attestation via Firebase App Check.
  - OS window protection (`FLAG_SECURE`) against screen capture and app-switcher snooping.
  - 5-minute inactivity session termination.
  - Responsive font scale auto-adjustment (`0.85` - `1.15`).

## Explicit non-goals

- No connection to core banking or transaction systems.
- No balances, transaction history, or transfers.
- No customer-facing access — staff-only tool.
- Account Number is never editable after creation (it's the database
  key — see ARCHITECTURE.md).

## Platform

Flutter, targeting Android (API 21+, Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20) and iOS. Firebase (free Spark plan — no
Cloud Functions, no billing required) for Auth and Firestore.
