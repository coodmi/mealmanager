import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { writeSysLog } from '../utils/logging';

export const softDeleteMess = onCall(async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const callerUid = request.auth.uid;
  const { messId } = request.data as { messId: string };

  if (!messId) {
    throw new HttpsError('invalid-argument', 'messId is required.');
  }

  const db = getFirestore();
  const messRef = db.collection('messes').doc(messId);
  const messSnap = await messRef.get();

  // Throw not-found if mess does not exist
  if (!messSnap.exists) {
    throw new HttpsError('not-found', `Mess ${messId} not found.`);
  }

  const messData = messSnap.data()!;

  // Throw permission-denied if caller is not the manager
  if (messData['managerId'] !== callerUid) {
    throw new HttpsError('permission-denied', 'Only the mess manager can delete this mess.');
  }

  const deletedAt = FieldValue.serverTimestamp();
  const deletedBy = callerUid;

  // Write to deleted_messes with all original fields + deletion metadata
  await db.collection('deleted_messes').doc(messId).set({
    ...messData,
    deletedAt,
    deletedBy,
    isDeleted: true,
    deletionReason: 'manager_request',
  });

  // Delete the root messes doc (subcollections remain)
  await messRef.delete();

  // Batch-update all users where messId == messId
  const membersSnap = await db.collection('users').where('messId', '==', messId).get();

  const BATCH_SIZE = 500;
  const memberDocs = membersSnap.docs;
  for (let i = 0; i < memberDocs.length; i += BATCH_SIZE) {
    const chunk = memberDocs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.update(doc.ref, { messId: '', role: 'member' });
    }
    await batch.commit();
  }

  // Write system log
  await writeSysLog(db, {
    type: 'soft_delete',
    messId,
    deletedBy,
    deletedAt,
    triggeredBy: callerUid,
  });

  return { success: true };
});
