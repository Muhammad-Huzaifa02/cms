import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../models/user_model.dart';

/// Handles login by EITHER email or phone number, both with password
/// (FR-1.1). Every account has a REAL email as its Firebase Auth identity
/// (email/password is Firebase's only native password provider). Phone
/// number is stored as a real, independent login path via a small public
/// lookup collection — `phoneIndex/{normalizedPhone} -> {email, uid}` —
/// so a phone-number sign-in resolves to the account's real email before
/// calling Firebase Auth. Both email and phone are mandatory on every
/// account precisely so this lookup always works.
///
/// [auth] and [db] are injectable so widget/unit tests can pass in
/// MockFirebaseAuth / FakeFirebaseFirestore instead of hitting real
/// Firebase. Production code just calls `AuthService()` and gets the
/// real singletons.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String normalizePhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. If this is left '
            'over from a failed attempt, delete it in Firebase Console → '
            'Authentication, or use a different email.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect login or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  /// [identifier] is either a real email or a phone number — auto-detected.
  Future<AppUser> signIn({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final isEmail = trimmed.contains('@');
    String loginEmail;

    if (isEmail) {
      loginEmail = trimmed;
    } else {
      final phoneDoc = await _db.collection('phoneIndex').doc(normalizePhone(trimmed)).get();
      final resolvedEmail = phoneDoc.data()?['email'] as String?;
      if (resolvedEmail == null) {
        throw Exception('No account found for that phone number.');
      }
      loginEmail = resolvedEmail;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(email: loginEmail, password: password);
      final user = cred.user;
      if (user == null) throw Exception('Authentication failed — no user returned.');
      
      final uid = user.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('No account record found for this login. Contact your Admin.');
      }
      final appUser = AppUser.fromDoc(doc);
      if (!appUser.active) {
        await _auth.signOut();
        throw Exception('This account has been deactivated. Contact your Admin.');
      }
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Used by Admin's "add staff" flow (FR-1.2/1.3). Creates the new Auth
  /// account on a SECOND, temporary Firebase app instance rather than the
  /// default one — this is the key trick. `createUserWithEmailAndPassword`
  /// always signs you in as the account you just created; running it on a
  /// throwaway secondary app means that sign-in happens there, not on the
  /// default app, so Admin's own session (on the default app) is never
  /// touched. No Cloud Function, no Blaze plan required — this all runs
  /// on Firebase's free Spark plan.
  ///
  /// The Firestore writes (users doc, phoneIndex, activityLog) still run
  /// on the DEFAULT app/Firestore instance, under Admin's own still-valid
  /// session — that's what lets `isAdmin()` in firestore.rules authorize
  /// them normally, same as any other Admin action.
  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required Permissions permissions,
    required String createdByUid,
  }) async {
    if (email.trim().isEmpty || phone.trim().isEmpty) {
      throw ArgumentError('Email and phone number are both required.');
    }

    final secondaryAppName = 'staffCreation_${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final UserCredential cred;
      try {
        cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw Exception(_friendlyAuthError(e));
      }
      final uid = cred.user!.uid;

      // Done with the secondary app immediately — sign it out and tear it
      // down so no lingering session sticks around on-device for it.
      await secondaryAuth.signOut();

      try {
        final batch = _db.batch();
        batch.set(_db.collection('users').doc(uid), {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'isAdmin': false,
          'permissions': permissions.toMap(),
          'active': true,
          'createdBy': createdByUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(_db.collection('phoneIndex').doc(normalizePhone(phone)), {
          'email': email.trim(),
          'uid': uid,
        });
        batch.set(_db.collection('activityLog').doc(), {
          'action': 'staff_created',
          'targetId': uid,
          'performedBy': createdByUid,
          'performedByName': (await loadAppUser(createdByUid))?.name ?? 'Admin',
          'timestamp': FieldValue.serverTimestamp(),
          'details': null,
        });
        await batch.commit();
      } catch (e) {
        // Firestore writes failed — clean up the orphaned Auth account via
        // the secondary app (which is still holding that user's session)
        // before it's torn down, so a partial failure doesn't leave an
        // unusable, undocumented login behind.
        await cred.user!.delete().catchError((_) => cred.user!);
        rethrow;
      }
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete().catchError((_) {});
      }
    }
  }

  /// Returns a stream of the app user document, emitting null if the doc
  /// doesn't exist yet. Useful for reactive UI (like AuthGate) that needs
  /// to wait for the Firestore doc to be created after Auth registration.
  Stream<AppUser?> appUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Future<AppUser?> loadAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// True if an Admin account already exists — used to decide whether the
  /// login screen should offer "Create Admin account" at all.
  Future<bool> adminAlreadyExists() async {
    final snap = await _db.collection('system').doc('bootstrap').get();
    return snap.data()?['adminExists'] == true;
  }

  /// Lets the branch manager create their OWN Admin account directly from
  /// the app, one time only, with no console/script step required. Guarded
  /// server-side by the /system/bootstrap flag in firestore.rules — once
  /// this succeeds, this path is permanently closed for everyone else.
  ///
  /// Name, email, phone, and password are ALL mandatory — email is the
  /// real Firebase Auth identity, phone is registered via `phoneIndex` so
  /// it works as a second, independent way to sign in to the same account.
  ///
  /// Self-healing: if a previous attempt got as far as creating the Auth
  /// account but failed before finishing the Firestore writes (network
  /// blip, rules not yet deployed, etc.), retrying with the same
  /// email+password signs into that leftover account and finishes setup,
  /// instead of permanently blocking on "email already in use".
  Future<AppUser> bootstrapFirstAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || phone.trim().isEmpty || password.length < 6) {
      throw ArgumentError('Name, email, phone, and a password of at least 6 characters are all required.');
    }
    final bootstrapRef = _db.collection('system').doc('bootstrap');

    // Make sure the flag doc exists so the very first run doesn't hit a
    // missing-document read in the security rule's get(). Safe to call
    // even if it already exists — rules only allow create with false.
    final flag = await bootstrapRef.get();
    if (!flag.exists) {
      await bootstrapRef.set({'adminExists': false});
    } else if (flag.data()?['adminExists'] == true) {
      throw Exception('An Admin account already exists. Please login instead.');
    }

    UserCredential cred;
    bool freshlyCreated = true;
    try {
      cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Recovery path: this email may be a leftover from an interrupted
        // attempt. Try signing into it with the password just entered —
        // if that succeeds, it's genuinely the same person retrying, so
        // finish setup on that account instead of creating a new one.
        try {
          cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
          freshlyCreated = false;
        } on FirebaseAuthException {
          throw Exception(
            'An account with this email already exists and this password '
            "doesn't match it. If this is left over from a failed attempt, "
            'delete it in Firebase Console → Authentication, or use a '
            'different email.',
          );
        }
      } else {
        throw Exception(_friendlyAuthError(e));
      }
    }
    
    final user = cred.user;
    if (user == null) throw Exception('Bootstrap failed — no user returned.');
    final uid = user.uid;

    try {
      await _db.runTransaction((tx) async {
        final current = await tx.get(bootstrapRef);
        if (current.exists && current.data()?['adminExists'] == true) {
          throw Exception('An Admin account already exists. Please login instead.');
        }
        tx.set(_db.collection('users').doc(uid), {
          'name': name,
          'email': email.trim(),
          'phone': phone.trim(),
          'isAdmin': true,
          'permissions': const Permissions(view: true, add: true, edit: true, delete: true).toMap(),
          'active': true,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(_db.collection('phoneIndex').doc(normalizePhone(phone)), {
          'email': email.trim(),
          'uid': uid,
        });
        tx.set(bootstrapRef, {'adminExists': true}, SetOptions(merge: true));
      });
    } catch (e) {
      // Only roll back an account we JUST created this call — never
      // delete a pre-existing account we merely signed into for recovery.
      if (freshlyCreated) {
        await cred.user!.delete().catchError((_) => cred.user!);
      }
      rethrow;
    }

    return AppUser(
      uid: uid,
      name: name,
      email: email.trim(),
      phone: phone.trim(),
      isAdmin: true,
      permissions: const Permissions(view: true, add: true, edit: true, delete: true),
      active: true,
      createdBy: uid,
    );
  }

  /// Lets a signed-in user edit their OWN name and phone number. Email is
  /// deliberately not editable here — it's the real Firebase Auth login,
  /// and changing it safely requires re-verification (Firebase deprecated
  /// direct email changes in favor of a verify-then-swap flow); out of
  /// scope for this self-edit screen. Password change is separate, see
  /// [changeOwnPassword].
  ///
  /// If the phone number changed, the old `phoneIndex` entry is removed
  /// and a new one registered, so phone-number sign-in keeps working with
  /// the new number and stops working with the old one.
  Future<void> updateOwnProfile({
    required String name,
    required String phone,
    required String previousPhone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You are not signed in.');
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
    if (phone.trim().isEmpty) throw ArgumentError('Phone number is required.');

    final newNormalized = normalizePhone(phone);
    final oldNormalized = normalizePhone(previousPhone);
    final currentEmail = _auth.currentUser?.email ?? '';

    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'name': name.trim(),
      'phone': phone.trim(),
    });
    if (newNormalized != oldNormalized) {
      if (oldNormalized.isNotEmpty) {
        batch.delete(_db.collection('phoneIndex').doc(oldNormalized));
      }
      batch.set(_db.collection('phoneIndex').doc(newNormalized), {
        'email': currentEmail,
        'uid': uid,
      });
    }
    await batch.commit();
  }

  /// Changes the signed-in user's own password. Firebase requires a
  /// "recent" login for this — if it's been a while since they signed in,
  /// this throws `requires-recent-login`, which the caller should turn
  /// into "please sign out and back in, then try again."
  ///
  /// If biometric login was enabled, its stored password is updated to
  /// match — otherwise biometric sign-in would silently start failing
  /// with the old password until the user manually re-enabled it.
  Future<void> changeOwnPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You are not signed in.');
    if (newPassword.length < 6) throw ArgumentError('Password must be at least 6 characters.');
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('For security, please sign out and sign back in before changing your password.');
      }
      throw Exception(_friendlyAuthError(e));
    }
    // Note: no biometric credential to sync anymore — biometric lock no
    // longer stores a password (see BiometricService's doc comment).
  }

  /// Step 1 of changing your own login email. Firebase deprecated direct
  /// `updateEmail()` in favor of this: it sends a verification link to the
  /// NEW address, and the Auth email only actually changes once that link
  /// is clicked. Deliberately does NOT touch Firestore yet — doing so
  /// immediately would desync `users.email` / `phoneIndex` from what
  /// Firebase Auth actually has until the person verifies, which would
  /// break their own login. Requires a recent sign-in; re-authenticates
  /// with the CURRENT password first so that's handled up front rather
  /// than surfacing a confusing `requires-recent-login` mid-flow.
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('You are not signed in.');
    final trimmed = newEmail.trim();
    if (!trimmed.contains('@')) throw ArgumentError('Enter a valid email address.');
    if (trimmed.toLowerCase() == user.email!.toLowerCase()) {
      throw ArgumentError('That\'s already your current email.');
    }

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Current password is incorrect.');
      }
      throw Exception(_friendlyAuthError(e));
    }

    try {
      await user.verifyBeforeUpdateEmail(trimmed);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  /// Step 2 — call this any time after requesting a change (e.g. a "I've
  /// verified my email" button). Reloads the Auth user; if the email has
  /// actually changed (meaning the link was clicked), syncs Firestore's
  /// `users.email` and the matching `phoneIndex` entry to match, and
  /// returns true. Returns false if it hasn't been verified yet — that's
  /// an expected, normal outcome, not an error.
  Future<bool> confirmEmailChangeIfVerified({required String phone}) async {
    var user = _auth.currentUser;
    if (user == null) throw Exception('You are not signed in.');
    await user.reload();
    user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    final storedEmail = doc.data()?['email'] as String?;
    if (storedEmail != null && storedEmail.toLowerCase() == user.email!.toLowerCase()) {
      return false; // Firestore already matches — nothing changed yet.
    }

    final batch = _db.batch();
    batch.update(_db.collection('users').doc(user.uid), {'email': user.email});
    final normalizedPhone = normalizePhone(phone);
    if (normalizedPhone.isNotEmpty) {
      batch.set(_db.collection('phoneIndex').doc(normalizedPhone), {
        'email': user.email,
        'uid': user.uid,
      });
    }
    await batch.commit();
    return true;
  }

  /// Sends a password-reset email via Firebase Auth. Works for any account
  /// since every account has a real, mandatory email — even ones that
  /// normally sign in by phone number.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }
}
