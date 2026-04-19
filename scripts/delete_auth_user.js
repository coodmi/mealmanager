/**
 * Run this script ONCE to delete a specific user from Firebase Auth.
 * Usage: node scripts/delete_auth_user.js <email>
 * Example: node scripts/delete_auth_user.js ronysphoto.02@gmail.com
 *
 * Requires: npm install firebase-admin (in project root or functions/)
 * Also requires: GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON
 * OR run from inside functions/ folder where admin is already initialized.
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Initialize with application default credentials
initializeApp({
  projectId: 'mealmanager-6a053',
});

const email = process.argv[2];
if (!email) {
  console.error('Usage: node scripts/delete_auth_user.js <email>');
  process.exit(1);
}

async function deleteUserByEmail(email) {
  const auth = getAuth();
  const db = getFirestore();

  try {
    // Get user by email
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;
    console.log(`Found user: ${uid} (${email})`);

    // Delete from Auth
    await auth.deleteUser(uid);
    console.log(`✅ Deleted from Firebase Auth: ${email}`);

    // Record in deleted_users
    await db.collection('deleted_users').doc(uid).set({
      email: email.toLowerCase(),
      deletedAt: FieldValue.serverTimestamp(),
    });
    console.log(`✅ Recorded in deleted_users collection`);

  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.log(`ℹ️  User not found in Auth (may already be deleted): ${email}`);
    } else {
      console.error('❌ Error:', err.message);
    }
  }
  process.exit(0);
}

deleteUserByEmail(email);
