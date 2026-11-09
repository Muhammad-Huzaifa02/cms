# 📖 CMS — Branch Customer Management System
## Official User & Customer Operations Guide

Welcome to the **Customer Management System (CMS)**. This manual provides branch managers, relationship managers, compliance officers, and branch banking staff with step-by-step operational instructions for customer onboarding, identity verification, communication, security compliance, and administrative reporting.

---

## Table of Contents
1. [System Overview & Access Roles](#1-system-overview--access-roles)
2. [First-Time Setup & Logging In](#2-first-time-setup--logging-in)
   - [Initial Admin Bootstrap](#initial-admin-bootstrap)
   - [Standard Staff Login & "Remember Me"](#standard-staff-login--remember-me)
   - [1-Tap Biometric Authentication](#1-tap-biometric-authentication)
3. [Customer Onboarding & Record Creation](#3-customer-onboarding--record-creation)
   - [Required vs. Optional Fields](#required-vs-optional-fields)
   - [Pakistani Banking Format Standards](#pakistani-banking-format-standards)
   - [Duplicate Prevention](#duplicate-prevention)
   - [Automated Welcome Notifications (SMS / WhatsApp)](#automated-welcome-notifications-sms--whatsapp)
4. [Customer Search & Identity Lookup](#4-customer-search--identity-lookup)
   - [Exact Field Search](#exact-field-search)
   - [Last-Four Digit Quick Lookup](#last-four-digit-quick-lookup)
   - [View-Only Context Protection](#view-only-context-protection)
5. [Customer Profile Operations](#5-customer-profile-operations)
   - [Data Masking & Tap-to-Reveal](#data-masking--tap-to-reveal)
   - [Sensitive Clipboard Auto-Sanitization (60s Timer)](#sensitive-clipboard-auto-sanitization-60s-timer)
   - [1-Tap Direct Customer Contact (Call & WhatsApp)](#1-tap-direct-customer-contact-call--whatsapp)
   - [Updating Customer Information](#updating-customer-information)
   - [Safe Customer Deletion Safeguard](#safe-customer-deletion-safeguard)
6. [Staff & Permission Administration (Branch Manager / Admin)](#6-staff--permission-administration-branch-manager--admin)
   - [Adding Staff Members](#adding-staff-members)
   - [Granular Permissions (View, Add, Edit, Delete)](#granular-permissions-view-add-edit-delete)
   - [Activating & Deactivating Staff Accounts](#activating--deactivating-staff-accounts)
7. [Reporting, Exports & Database Backups (Admin Only)](#7-reporting-exports--database-backups-admin-only)
   - [Excel (.xlsx) Branch Reports](#excel-xlsx-branch-reports)
   - [Executive PDF Digest with Distribution Ratios](#executive-pdf-digest-with-distribution-ratios)
   - [SHA-256 Cryptographic Verification](#sha-256-cryptographic-verification)
   - [Full JSON Database Vault Backup](#full-json-database-vault-backup)
   - [Immutable Activity Audit Log](#immutable-activity-audit-log)
8. [Security Features & Compliance Policies](#8-security-features--compliance-policies)
   - [Device Integrity Guard](#device-integrity-guard)
   - [Privacy Shield (Anti-Screen Capture)](#privacy-shield-anti-screen-capture)
   - [5-Minute Inactivity Auto-Lock](#5-minute-inactivity-auto-lock)
   - [Brute-Force Rate Limiter](#brute-force-rate-limiter)
9. [In-App Software Updates](#9-in-app-software-updates)
10. [Troubleshooting & Frequently Asked Questions (FAQ)](#10-troubleshooting--frequently-asked-questions-faq)

---

## 1. System Overview & Access Roles

The Customer Management System (CMS) operates independently of core banking networks, enabling branch officers to rapidly verify customer identities, manage contact information, dispatch automated customer notifications, and maintain tamper-evident audit logs.

### Access Levels:
| Role | Capabilities | Primary Users |
| :--- | :--- | :--- |
| **Branch Manager (Admin)** | Full system control: Add/Edit/Delete customers, manage staff credentials and permissions, generate Excel/PDF audit reports, download database backups, and inspect the activity log. | Branch Manager, Operations Head |
| **Branch Staff** | Role-gated operations: Customer lookups, customer additions, profile updates, and direct customer communication according to assigned permissions (`view`, `add`, `edit`, `delete`). | Relationship Managers, Cashiers, Customer Support Officers |

---

## 2. First-Time Setup & Logging In

### Initial Admin Bootstrap
When opening the application on a newly deployed branch database:
1. The app detects that no administrator exists and automatically presents the **Create Administrator** screen.
2. Enter the Branch Manager's **Full Name**, **Branch Code**, **Official Email**, **Mobile Number**, and a strong **Password**.
   > **Password Requirement**: Minimum 8 characters, containing at least 1 uppercase letter (`A-Z`), 1 lowercase letter (`a-z`), 1 numeric digit (`0-9`), and 1 special symbol (`!@#$%^&*`).
3. Tap **Create Admin Account**. The account is created immediately with complete system privileges.

### Standard Staff Login & "Remember Me"
1. Open the app to the **Sign In** screen.
2. Enter your registered **Email Address** OR your registered **Pakistani Mobile Number** (e.g., `03001234567`).
3. Enter your account **Password**.
4. Check **Remember Me** to securely store your sign-in identifier on the device's hardware keychain (`FlutterSecureStorage`). On future launches, your identifier will be prefilled automatically.
5. Tap **Sign In**.

### 1-Tap Biometric Authentication
Once you have logged in with your password at least once:
1. Tap the **Fingerprint / Biometric Sensor Icon** located on the login card.
2. Verify using your device's fingerprint scanner or Face Unlock.
3. You will be authenticated immediately into the dashboard without typing your password.
> *Note: If you change your password in "My Account", your biometric vault automatically updates with your new credentials.*

---

## 3. Customer Onboarding & Record Creation

To register a new customer in the branch system, tap **Add Customer** from the Dashboard or bottom navigation.

### Required vs. Optional Fields
- **Required**:
  - **Account Title**: Full legal customer name as printed on their CNIC/passport.
  - **Account Number**: Exactly 14 numeric digits.
  - **Mobile Phone**: Exactly 11 numeric digits starting with `03xx`.
  - **CNIC**: Exactly 13 numeric digits without hyphens.
  - **Account Type**: Savings, Current, or Business.
  - **Account Status**: Active, Inactive, Dormant, or Blocked.
  - **Gender**: Male, Female, or Other.
- **Optional**:
  - **Customer Email**: Valid electronic mail address for digital communication.
  - **IBAN**: Exactly 24 alphanumeric characters starting with `PK`.
  - **Residential / Business Address**: Full street, area, and city details.
  - **Internal Notes**: Operational reminders or compliance flags.

### Pakistani Banking Format Standards
The system automatically validates entries against standard Pakistani banking rules:
- **Mobile Number**: `03001234567` (11 digits, valid mobile operator codes).
- **CNIC**: `3520112345671` (13 continuous numeric digits).
- **Account Number**: `12345678901234` (14 digits).
- **IBAN**: `PK36SCBL0000001123456701` (24 characters, prefix `PK`).

### Duplicate Prevention
Before writing to the database, the system validates whether the entered **Mobile Phone** or **CNIC** is already assigned to an existing customer. If a duplicate is detected, an alert prompts you with the existing customer record to prevent duplicate profiles.

### Automated Welcome Notifications (SMS / WhatsApp)
Upon tapping **Save Customer**:
- An automated notification receipt dialog appears giving you 1-tap options:
  - **Send WhatsApp Message**: Opens WhatsApp with a prefilled, professional welcome message containing the customer's Account Title, Masked Account Number, and Branch details.
  - **Send SMS**: Launches the native SMS messenger with a formatted welcome receipt ready to send.
  - **Skip**: Closes the dialog if the customer opted out of instant digital receipts.

---

## 4. Customer Search & Identity Lookup

For rapid branch counter operations, use the **Search** screen.

### Exact Field Search
The search system eliminates false-positive clutter by searching strictly by specific fields:
1. Select the search filter chip: **Account Title**, **Account Number**, **Phone Number**, or **CNIC**.
2. Type the query into the search bar. Results update with debounced sub-millisecond offline indexing.

### Last-Four Digit Quick Lookup
If a customer only remembers the end of their account number, mobile, or CNIC:
- Enter the **last 4 digits** into the search field.
- The system checks indexed last-four suffix tables and retrieves matching records instantly.

### View-Only Context Protection
To prevent accidental modifications while looking up customers at the counter:
- Tapping a customer card from the **Dashboard** or **Search Results** opens their profile in **Strict View-Only Mode**.
- Editing is exclusively permitted through the dedicated **Customer Management** module by authorized staff.

---

## 5. Customer Profile Operations

### Data Masking & Tap-to-Reveal
To protect customer privacy from over-the-shoulder viewing at branch counters:
- **CNIC**, **Account Number**, and **Mobile Phone** are masked by default (e.g., `•••• •••• ••5671`).
- Tap the **Eye Icon** next to any field to unmask and inspect the complete numbers.

### Sensitive Clipboard Auto-Sanitization (60s Timer)
When tapping the **Copy** button on an Account Number, IBAN, CNIC, or Phone:
- The text is copied to your clipboard with a confirmation notification.
- **Security Timer**: The application starts a 60-second countdown. At the end of 60 seconds, the device clipboard is automatically purged, preventing other apps from reading sensitive banking data.

### 1-Tap Direct Customer Contact (Call & WhatsApp)
Under the customer's contact card:
- **Call Button**: Immediately dials the customer's mobile number via the device phone dialer.
- **WhatsApp Button**: Opens a direct encrypted WhatsApp chat with the customer without having to manually save them in your phone's personal contact book.

### Updating Customer Information
1. Open **Customer Management** (requires `Edit` permission).
2. Select the customer and tap **Edit Profile**.
3. Modify contact numbers, address, or account status.
4. Tap **Save Changes**. An automated record update notification (SMS/WhatsApp) prompt will be offered to inform the customer.

### Safe Customer Deletion Safeguard
To eliminate accidental deletion of customer banking records:
1. Only users with **Delete** permissions will see the delete option.
2. Tapping **Delete Customer** displays a high-security modal.
3. The officer **must manually type the customer's exact 14-digit Account Number** into the confirmation box.
4. The **Confirm Deletion** button only enables once all 14 digits match exactly.
5. All deletions are permanently recorded in the immutable **Activity Audit Log**.

---

## 6. Staff & Permission Administration (Branch Manager / Admin)

Branch Managers can manage all branch officers under **Staff Management**:

### Adding Staff Members
1. Tap **Add Staff**.
2. Enter the officer's **Full Name**, **Official Email**, **Mobile Number**, and initial **Password**.
3. Select which permissions this officer should hold:
   - `Can View Customers`
   - `Can Add Customers`
   - `Can Edit Customers`
   - `Can Delete Customers`
4. Tap **Create Staff Account**.

### Granular Permissions
Managers can adjust staff privileges at any time:
- Tap on any staff member's profile card.
- Toggle individual switches (e.g., granting a junior clerk `View` and `Add` permissions while disabling `Edit` and `Delete`).
- Changes take effect immediately across all active sessions.

### Activating & Deactivating Staff Accounts
If a staff member is transferred or leaves the branch:
- Toggle the **Account Active** switch to `Inactive`.
- The user is immediately blocked from signing in or reading data.

---

## 7. Reporting, Exports & Database Backups (Admin Only)

Under the **Exports & Reports** section, Branch Managers have access to data governance tools:

### Excel (.xlsx) Branch Reports
- Generates a full spreadsheet containing customer rosters, contact details, account statuses, and branch timestamps.
- Formatted with headers and column auto-sizing for Microsoft Excel and Google Sheets.

### Executive PDF Digest with Distribution Ratios
- Produces a formal, executive banking report with official headers.
- Includes a **Branch Distribution Summary Digest**:
  - Active vs. Dormant vs. Blocked customer ratios.
  - Savings vs. Current vs. Business account breakdowns.
  - Clean printable table ready for branch compliance audits.

### SHA-256 Cryptographic Verification
- Every generated export computes an on-the-fly **SHA-256 cryptographic hash fingerprint**.
- The hash is displayed on screen and embedded in the file, allowing auditors to mathematically verify that the exported document has not been altered or tampered with.

### Full JSON Database Vault Backup
- Generates an encrypted, single-file raw JSON backup of all customer records.
- Can be saved locally, emailed to branch headquarters, or backed up to an offsite secure storage vault for disaster recovery.

### Immutable Activity Audit Log
- Every critical operation is permanently recorded under **Activity Log**:
  - Customer additions, updates, and deletions (with before/after diffs).
  - Staff creation and permission adjustments.
  - Report exports and backup downloads.
  - Timestamps, responsible officer ID, and client IP metadata.

---

## 8. Security Features & Compliance Policies

### Device Integrity Guard
The application contains embedded hardware security scanning. If an attempt is made to run the system on a **rooted device**, a **jailbroken phone**, or inside an **unauthorized emulation hook (Frida / Xposed)**, the app will instantly terminate with a security warning to protect customer records.

### Privacy Shield (Anti-Screen Capture)
Operating under Android's `FLAG_SECURE` standard:
- Taking screenshots or recording screen video inside the app is blocked by the operating system.
- When switching between apps on Android, the app switcher preview is blacked out to prevent visual eavesdropping.

### 5-Minute Inactivity Auto-Lock
If no touch interactions occur for **5 continuous minutes**:
- The session is automatically locked.
- A circular biometric lock screen covers the screen.
- The officer must re-authenticate with their fingerprint or account password to resume work.

### Brute-Force Rate Limiter
If 5 consecutive incorrect passwords are entered on the login screen, the system automatically engages a **30-second lockout timer** to defeat automated password dictionary attacks.

---

## 9. In-App Software Updates

The app includes an integrated version monitor:
- When branch administration publishes a new version, an in-app banner notifies staff: *"A new version is available"*.
- Tapping **Update Now** shows release notes and downloads the verified release APK directly, eliminating manual installation delays.

---

## 10. Troubleshooting & Frequently Asked Questions (FAQ)

#### Q1: Why am I getting "Permission Denied" when trying to edit a customer?
**A:** Your user account does not have the `Can Edit Customers` permission enabled. Contact your Branch Manager to update your permissions in Staff Management.

#### Q2: What should I do if a customer has a 10-digit mobile number?
**A:** Standard Pakistani mobile numbers are 11 digits (e.g., `03001234567`). Verify the customer's network prefix and ensure the leading zero is included.

#### Q3: Why does my clipboard get cleared after copying an account number?
**A:** This is an intentional security safeguard. Sensitive financial numbers (Accounts, IBANs, CNICs) are auto-cleared after 60 seconds to prevent unauthorized background apps from capturing customer information.

#### Q4: How do I recover an account if I forgot my password?
**A:** Contact your Branch Manager. The Branch Manager can update your staff credentials or reset your account through the Staff Management panel.

#### Q5: Can I use the app while offline?
**A:** Yes. The application features local Firestore persistence. You can search, view, and inspect existing customer records without an internet connection. Any additions or updates will automatically synchronize once connectivity is restored.

---

*Customer Management System (CMS) — Confidential & Proprietary Banking Operations Document.*
