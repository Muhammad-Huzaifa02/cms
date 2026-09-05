/**
 * Run once, locally, to create the very first Admin login for CMS.
 * There is no default/built-in admin account — this script (or the
 * equivalent manual steps in the Firebase Console) is how you create it.
 *
 * Setup:
 *   1. Firebase Console → Project Settings → Service Accounts →
 *      "Generate new private key" → save as serviceAccountKey.json
 *      in this same tools/ folder (keep it out of git!).
 *   2. npm install firebase-admin
 *   3. node create_first_admin.js
 *
 * Edit the three constants below before running.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ---- EDIT THESE THREE VALUES ----
const ADMIN_NAME = 'Branch Manager';
const ADMIN_EMAIL = 'manager@meezanbank.example.com'; // or use a phone-based synthetic email — see auth_service.dart
const ADMIN_PASSWORD = 'ChangeThisPassword123!'; // change immediately after first login
// ----------------------------------

async function main() {
  const userRecord = await admin.auth().createUser({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    displayName: ADMIN_NAME,
  });

  await admin.firestore().collection('users').doc(userRecord.uid).set({
    name: ADMIN_NAME,
    email: ADMIN_EMAIL,
    phone: null,
    isAdmin: true,
    permissions: { view: true, add: true, edit: true, delete: true },
    active: true,
    createdBy: 'system',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('Admin account created.');
  console.log('UID:', userRecord.uid);
  console.log('Login email:', ADMIN_EMAIL);
  console.log('Log in with this email + the password you set above, then change the password from within the app / Firebase Console.');
}

main().catch((err) => {
  console.error('Failed to create admin account:', err.message);
  process.exit(1);
});
