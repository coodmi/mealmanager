const { onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

/**
 * Triggered when an admin deletes a user document from Firestore.
 * Automatically deletes the corresponding Firebase Auth account.
 */
exports.onUserDeleted = onDocumentDeleted('users/{userId}', async (event) => {
  const userId = event.params.userId;
  const deletedData = event.data?.data();
  const email = deletedData?.email ?? '';

  const auth = getAuth();
  const db = getFirestore();

  // 1. Delete from Firebase Auth
  try {
    await auth.deleteUser(userId);
    console.log(`Auth account deleted for uid: ${userId}`);
  } catch (err) {
    // User may not exist in Auth (e.g. manually created Firestore doc)
    console.warn(`Could not delete Auth user ${userId}:`, err.message);
  }

  // 2. Record in deleted_users so re-registration is blocked
  if (email) {
    try {
      await db.collection('deleted_users').doc(userId).set({
        email: email.toLowerCase(),
        deletedAt: FieldValue.serverTimestamp(),
      });
      console.log(`Recorded deleted email: ${email}`);
    } catch (err) {
      console.warn('Could not record deleted_users:', err.message);
    }
  }
});
