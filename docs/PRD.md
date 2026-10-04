# PRD — CMS (Customer Management System)

## What this is

An internal branch tool for Meezan Bank. A branch manager (Admin) and
their staff use it to look up, add, and edit customer contact/identity
records — name, Account Title, phone, CNIC, account number, account
type. It is **independent of core banking**: no real-time connection to
transaction systems, no balances, no transfers. It exists to answer one
question fast: "who is this customer, and what's their account number?"

## Users

- **Admin** — the branch manager. Exactly one exists per deployment,
  created via a one-time in-app self-setup flow (no console/script
  step). Full access to everything, always.
- **Staff** — created only by Admin, from inside the app. Each staff
  account has its own, individually-assigned permissions: `view`,
  `add`, `edit`, `delete` — no fixed role names like "Editor" or
  "Viewer". Admin can grant any combination per person.

There is no self-registration. Nobody creates their own account except
Admin, once, on first run.

## Core functional requirements

- **Login**: email OR phone number, both with a password. Both are
  mandatory on every account (see ARCHITECTURE.md for why).
- **Search**: by name, Account Title, phone, CNIC, or account number —
  full value or last-4-digits partial match on the numeric fields.
- **Add/Edit customer**: Full Name, Account Title, Phone, CNIC, Account
  Number, Account Type, Address, Notes. Strict Pakistani-format
  validation on Phone/CNIC/Account Number (see RULES.md). Duplicate
  Phone/CNIC rejected with a clear message.
- **Masking**: CNIC and Account Number are masked (last 4 digits shown)
  everywhere by default, with a tap-to-reveal.
- **Staff management**: Admin creates staff accounts and sets each
  one's permissions; can toggle active/inactive at any time.
- **Activity log**: append-only audit trail (who added/edited/deleted
  what, and staff/permission changes), visible to Admin only.
- **Export**: Admin-only, to Excel or PDF, logged to the activity log.
- **My Account**: any signed-in user can edit their own name and phone,
  change their password, change their login email (with real
  verification), and enable/disable a biometric app-lock.

## Explicit non-goals

- No connection to core banking or transaction systems.
- No balances, transaction history, or transfers.
- No customer-facing access — staff-only tool.
- Account Number is never editable after creation (it's the database
  key — see ARCHITECTURE.md).

## Platform

Flutter, targeting Android and iOS. Firebase (free Spark plan — no
Cloud Functions, no billing required) for Auth and Firestore.
