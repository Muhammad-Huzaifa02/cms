# RULES — conventions any change to this project must follow

## Validation (strict Pakistani formats — do not loosen these)

All three live in `core/utils/validators.dart` as the single source of
truth. Customer forms AND Staff forms must use the same `Validators`
class — do not write a second, slightly-different phone check
somewhere else.

- **Phone**: exactly 11 digits, digits only, must start with `03`.
  Error: *"Phone number must be a valid Pakistani mobile number with
  exactly 11 digits."*
- **CNIC**: exactly 13 digits, digits only, no dashes/spaces. Do not
  silently strip separators the user typed — reject with the message,
  don't "fix" it for them. Error: *"CNIC must contain exactly 13
  digits."*
- **Account Number**: exactly 14 digits, digits only. Error: *"Account
  number must contain exactly 14 digits."*
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

## Search — field isolation is a hard rule

User-facing customer search must only ever query the single field the
user picked (Account Title, Account Number, Phone, or CNIC). Never add a
"search everything" box and never route user search through the shared
`searchKeywords` array: last-4 digits routinely coincide across different
fields for different customers, so a combined search returns the wrong
person. Phone/CNIC/Account Number search takes exactly 4 digits and
queries its own dedicated `*Last4` field. `SearchResultsScreen` requires
a `CustomerSearchField` on purpose — keep it required so a global search
can't be reached by accident.

Any change to how phone, CNIC, account number or account title are
stored must keep `Customer.toMap()` writing the matching `*Last4` /
`accountTitleSearchWords` fields, and existing customers then need
"Sync search index" run once.

## Data integrity

- **Account Number is never editable after creation.** It's the
  Firestore document ID. "Changing" it would mean delete-old-doc +
  create-new-doc, which orphans every `activityLog` entry that
  references the old ID. If this is ever genuinely needed, it must be
  a deliberate, explicit Admin action with its own confirmation and
  log entry — not a side effect of an edit form.
- **`activityLog` is append-only.** Never add an update or delete path
  for it, in code or in rules, for any reason, including for Admin.
- **CNIC and Account Number are masked (last 4 digits) by default**
  everywhere they're displayed — detail screens, search results,
  recent-customer lists. Reveal is an explicit tap, never automatic.

## Security

- **Never store a password anywhere** except transiently in memory to
  send to Firebase Auth. This includes biometric login — see
  ARCHITECTURE.md's biometric section. If a future change proposes
  storing a password "to make login easier," it should be treated as a
  suggestion to reconsider, not implemented as asked.
- Every permission check in the UI (`AppUser.can('edit')` etc.) must
  have a matching, independent check in `firestore.rules`. The UI check
  prevents bad UX; the rule prevents a bad actor. Neither replaces the
  other.
- Firebase project stays on the **free Spark plan** — no Cloud
  Functions, no feature that requires the Blaze (pay-as-you-go) plan.
  If a future request seems to need server-side/Admin-SDK logic, look
  for a client-side alternative first (e.g. the secondary-app-instance
  pattern for staff creation) before reaching for Cloud Functions.

## Process

- Don't downgrade Flutter, Gradle, the Android Gradle Plugin, or
  Kotlin to fix a dependency issue — find a compatible version instead.
- After any change, do a full brace/paren balance pass and a search
  for stale references (renamed methods, removed imports) across the
  *whole* project, not just the files touched — this project has hit
  compile-breaking regressions before from a change in one file not
  being propagated to a caller in another.
- `firestore.rules` changes require a deploy to take effect. Say so
  explicitly whenever the rules file changes.
