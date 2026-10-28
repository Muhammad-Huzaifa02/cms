# Security Baseline Update

This file records Firestore rule and customer-service hardening on the extracted workspace copy. It has not been deployed to Firebase. The uploaded archive and original source were left unchanged.

## Changes made in `firestore.rules`

- Bootstrap can only change from false to true when the same atomic operation creates/updates the caller's Admin user document with `createdBy` equal to that caller. Unrelated authenticated users can no longer claim the setup flag by themselves.
- Bootstrap initialization remains open to create the false flag because the first-run app flow depends on that. This means the first Admin is still whoever completes the unclaimed bootstrap first; production provisioning policy must account for that.
- The phone index cannot be listed as a collection. Exact-document reads remain public so phone-number login can resolve an email without a signed-in session. That exact lookup still exposes an email and UID to someone who knows or guesses a phone number; eliminating that exposure needs a backend lookup, a different authentication flow, or dropping phone/password login.
- Phone-index writes are constrained to the account owner or Admin and validate the phone document key. Owners can sync their own index email only to the email in their authenticated Firebase token.
- Customer writes now validate account number, Pakistani phone and CNIC formats, actor attribution, and server timestamps. Updates preserve the account number and creation metadata. Admin search-index backfill is allowed to change only the four derived search fields and the reserved delete-event ID.
- User self-updates are restricted to name, phone, and email while keeping role, active status, permissions, creator, and creation time unchanged. Phone/name formats are checked; email must match the authenticated token.
- Customer create/update/delete now writes the customer change and its audit entry in one Firestore transaction. Rules cross-check both sides with `getAfter()` and deny either write if the matching half is missing. Each customer stores a reserved delete-event ID so deletion can be paired with a new append-only record. The Admin search-index sync also backfills that token for existing records.
- Staff creation writes the user record and its event in the same batch. Permission and active-state changes use transactions; rules require the matching staff event and state change in that same transaction.
- All activity creation checks actor UID/name, event vocabulary, timestamp, and role/permission. Export events remain client-created separately from local file generation; activity-log update/delete remain denied.

## Remaining security limits

- Customer and staff-management events are now coupled to their Firestore changes under the proposed rules. Export events remain client-written separately from local file generation and can be omitted or forged by a permitted Admin. Customer and staff changes require online transactions, and existing customer records need the Admin index sync to populate reserved delete-event IDs before the stricter rules are deployed. A paid backend is not required for these database-event pairs.
- Phone/CNIC duplicate checks still have a concurrency window and are not globally enforced by these rules. Strong uniqueness needs a race-safe reservation/index design or trusted server transaction.
- Staff Admin writes remain powerful by design; Admin account compromise exposes customer records and exports.
- Customer PII remains readable to any active account with `view`; masking is only a UI display behavior. Exported files contain full identifiers under the current product design.
- Existing Firestore records must be compatible with the new write invariants before edits, index backfill, or staff self-service updates are relied on. Legacy documents with malformed data can fail writes and need a migration/review plan.

## Required before deployment

1. Run the Admin “Sync search index” once against existing data to add the reserved delete-event IDs before deploying these rules.
2. Run the Firestore Emulator suite with `npm run test:rules`. It covers unauthenticated listing versus exact phone-index reads, bootstrap protection, customer CRUD/event pairing, staff create/permission/active-state pairing, inactive users, and append-only audit entries.
3. Review the first-admin enrollment and phone-index exposure with the project owner.
4. Test the app flows against a non-production Firebase project, including audit-token backfill and verified email change.
5. Only after those checks, deploy with `firebase deploy --only firestore:rules` (or publish the rules in Firebase Console) and verify the deployed rules. Editing this local file alone does not change the live Firebase project.
