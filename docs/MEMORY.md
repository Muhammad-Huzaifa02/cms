# MEMORY — decisions already made, don't re-litigate or silently revert

This file exists because several of these exact decisions have been
**accidentally reverted** by a later change that rebuilt the same screen
without knowing why it looked the way it did. Read this before touching
the files it references.

## "Always show the Sign In screen first" — settled, do not add
"smart" routing back

`main.dart` always routes a signed-out user to `LoginScreen`. An earlier
version tried to be clever and auto-route to `CreateAdminScreen` when no
Admin existed yet, skipping Login entirely. **This was explicitly
rejected** — the person managing this app wanted Login to always be the
first thing shown, full stop. The "Create the Admin account" link
already lives on the Login screen itself and self-hides once an Admin
exists (`AuthService.adminAlreadyExists()`); that's the correct way to
surface first-run setup, not a routing branch in `main.dart`.

## Dashboard header size — settled at 138px, keep it there

The `SliverAppBar`'s `expandedHeight` has been fixed at **138**, name
text at **18sp**, and the decorative logo watermark at **90px**,
multiple times, after it kept creeping back up to 200px / 26sp / 220px
whenever someone rebuilt the header (e.g. when adding the Drawer nav).
If a future change touches `dashboard_screen.dart`'s header, preserve
these exact values rather than eyeballing new ones.

## Biometric is an app-lock, not a login mechanism — settled

Explicitly considered and rejected: storing the account password
(even encrypted) to let biometrics "log in" a fully signed-out user.
Rejected because storing a password anywhere is a bigger attack surface
than necessary, and it's unneeded — Firebase already persists the
session across restarts on its own. Biometrics is a manual-tap gate in
front of that persisted session. If a future request asks for
"fingerprint login on the login screen for a signed-out user," that is
this exact same request in different words — point back to this
decision rather than re-implementing password storage.

## No Cloud Functions — settled, stay on free Firebase

Cloud Functions were implemented once (for staff creation, the
"correct" server-side fix for the Admin-session-swap bug) and then
**deliberately removed** when it turned out Cloud Functions requires
Firebase's Blaze plan (a billing card on file, even for $0 actual
usage). The person running this app does not have/want a paid Firebase
plan. The replacement — a temporary second Firebase app instance,
client-side — solves the same bug without needing Blaze. Do not
reintroduce Cloud Functions unless the person explicitly says they now
have a Blaze plan and want to.

## Supabase was considered and rejected

A full Firebase→Supabase migration was proposed by the person, but the
stated reason (Cloud Functions requiring a paid plan) was resolved by
the fix above instead. When asked directly whether to still migrate
given that, the answer was **no, stay on Firebase**. Don't propose this
migration again unless something *new* motivates it.

## Firestore rules must be redeployed — this has caused real bugs

At least one `permission-denied` production bug was caused purely by
`firestore.rules` being edited locally but never deployed
(`firebase deploy --only firestore:rules`, or pasted into Firebase
Console → Firestore → Rules → Publish). Whenever this file changes,
say so explicitly and remind that it needs deploying — don't assume a
local edit takes effect on its own.

## `Curves.easeOutBack` + `Opacity` — a bug class, not a one-off

This exact crash (`'opacity >= 0.0 && opacity <= 1.0': is not true`) has
been fixed **three separate times** in three different files, because a
bounce/elastic curve's value was fed straight into `Opacity` without
clamping. See DESIGN.md. If you're adding a new entrance animation with
a bouncy curve, clamp the opacity from the start.

## Account Title / strict Pakistani validation / duplicate checks —
mostly pre-existing, verify before assuming missing

A large chunk of Customer/Staff validation (11-digit `03`-prefix phone,
13-digit CNIC, 14-digit account number, Account Title, duplicate
phone/CNIC rejection) already exists in `core/utils/validators.dart`
and `CustomerService`. Before re-implementing any of this from a fresh
spec, check whether it's already there — it has been built and rebuilt
more than once because it wasn't checked for first.
