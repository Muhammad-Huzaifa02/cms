const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

/**
 * Creates a staff account entirely server-side: Auth user, `users/{uid}`
 * doc, `phoneIndex` entry, and an activityLog record — all via the Admin
 * SDK, which never touches the CALLER's own client session.
 *
 * This replaces the previous client-side approach, where
 * `createUserWithEmailAndPassword` on the client would silently sign the
 * Admin out of their own account and into the brand-new staff account
 * instead (a documented Firebase Auth client-SDK quirk: creating a user
 * signs you in as that user). That was flagged as a scaffold shortcut
 * from day one — this is the real fix.
 *
 * Call from Flutter via:
 *   FirebaseFunctions.instance.httpsCallable('createStaffAccount').call({...})
 */
exports.createStaffAccount = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  // Verify the CALLER is an active Admin — this is the server-side
  // enforcement that a client-side check alone could never guarantee.
  const callerDoc = await db.collection('users').doc(callerUid).get();
  const caller = callerDoc.data();
  if (!callerDoc.exists || caller.isAdmin !== true || caller.active !== true) {
    throw new HttpsError('permission-denied', 'Only an active Admin can create staff accounts.');
  }

  const { name, email, phone, password, permissions } = request.data || {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    throw new HttpsError('invalid-argument', 'Name is required.');
  }
  if (!email || typeof email !== 'string' || !email.includes('@')) {
    throw new HttpsError('invalid-argument', 'A valid email is required.');
  }
  if (!phone || typeof phone !== 'string' || !phone.trim()) {
    throw new HttpsError('invalid-argument', 'Phone number is required.');
  }
  if (!password || typeof password !== 'string' || password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  const safePermissions = {
    view: !!(permissions && permissions.view),
    add: !!(permissions && permissions.add),
    edit: !!(permissions && permissions.edit),
    delete: !!(permissions && permissions.delete),
  };

  const normalizedPhone = phone.replace(/[^0-9]/g, '');
  const trimmedEmail = email.trim();

  let newUser;
  try {
    newUser = await auth.createUser({
      email: trimmedEmail,
      password,
      displayName: name.trim(),
    });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'An account with this email already exists.');
    }
    throw new HttpsError('internal', err.message || 'Could not create the account.');
  }

  try {
    const batch = db.batch();
    batch.set(db.collection('users').doc(newUser.uid), {
      name: name.trim(),
      email: trimmedEmail,
      phone: phone.trim(),
      isAdmin: false,
      permissions: safePermissions,
      active: true,
      createdBy: callerUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('phoneIndex').doc(normalizedPhone), {
      email: trimmedEmail,
      uid: newUser.uid,
    });
    batch.set(db.collection('activityLog').doc(), {
      action: 'staff_created',
      targetId: newUser.uid,
      performedBy: callerUid,
      performedByName: caller.name || 'Admin',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: null,
    });
    await batch.commit();
  } catch (err) {
    // Roll back the orphaned Auth account if the Firestore writes failed,
    // so a partial failure doesn't leave an unusable, undocumented login.
    await auth.deleteUser(newUser.uid).catch(() => {});
    throw new HttpsError('internal', 'Account was created but setup failed — rolled back. Please try again.');
  }

  return { uid: newUser.uid };
});
