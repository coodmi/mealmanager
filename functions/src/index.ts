import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp();

/**
 * Triggered when an admin deletes a user document from Firestore.
 * Automatically deletes the corresponding Firebase Auth account.
 */
export const onUserDeleted = onDocumentDeleted('users/{userId}', async (event) => {
  const userId = event.params.userId;
  const deletedData = event.data?.data();
  const email = (deletedData?.['email'] as string | undefined) ?? '';

  const auth = getAuth();
  const db = getFirestore();

  // 1. Delete from Firebase Auth
  try {
    await auth.deleteUser(userId);
    console.log(`Auth account deleted for uid: ${userId}`);
  } catch (err) {
    // User may not exist in Auth (e.g. manually created Firestore doc)
    console.warn(`Could not delete Auth user ${userId}:`, (err as Error).message);
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
      console.warn('Could not record deleted_users:', (err as Error).message);
    }
  }
});

// ---------------------------------------------------------------------------
// Stubs — implemented in subsequent tasks
// ---------------------------------------------------------------------------

// Triggers
export { updateLastActivity } from './triggers/updateLastActivity';

// Callables
export { softDeleteMess } from './callable/softDeleteMess';
export { restoreMess } from './callable/restoreMess';

// Scheduled cleanup jobs
export { cleanupEphemeralData } from './cleanup/cleanupEphemeralData';
export { cleanupMessOperationalData } from './cleanup/cleanupMessOperationalData';
export { cleanupInactiveMesses } from './cleanup/cleanupInactiveMesses';
export { cleanupExpiredDeletedMesses } from './cleanup/cleanupExpiredDeletedMesses';
