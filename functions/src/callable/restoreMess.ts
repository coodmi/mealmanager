import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { writeSysLog } from '../utils/logging';

const ADMIN_ROLES = ['superAdmin', 'systemAdmin', 'supportAdmin', 'contentAdmin'];

export const restoreMess = onCall(async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  // Require admin role via custom claims
  const role = request.auth.token['role'] as string | undefined;
  if (!role || !ADMIN_ROLES.includes(role)) {
    throw new HttpsError('permission-denied', 'Caller does not have an admin role.');
  }

  const callerUid = request.auth.uid;
  const { messId } = request.data as { messId: string };

  if (!messId) {
    throw new HttpsError('invalid-argument', 'messId is required.');
  }

  const db = getFirestore();
  const deletedRef = db.collection('deleted_messes').doc(messId);
  const deletedSnap = await deletedRef.get();

  // Throw not-found if deleted mess does not exist
  if (!deletedSnap.exists) {
    throw new HttpsError('not-found', `Deleted mess ${messId} not found.`);
  }

  const data = deletedSnap.data()!;

  // Check 30-day recovery window
  const deletedAtDate = (data['deletedAt'] as Timestamp).toDate();
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  if (deletedAtDate < thirtyDaysAgo) {
    throw new HttpsError('failed-precondition', 'Recovery window expired');
  }

  // Build restored document: spread original fields, omit deletion metadata, add restoredAt
  const { isDeleted: _isDeleted, deletedAt: _deletedAt, deletedBy: _deletedBy, deletionReason: _deletionReason, ...originalFields } = data;
  const restoredAt = FieldValue.serverTimestamp();

  // Write back to messes collection
  await db.collection('messes').doc(messId).set({
    ...originalFields,
    restoredAt,
  });

  // Remove from deleted_messes
  await deletedRef.delete();

  // Write system log
  await writeSysLog(db, {
    type: 'mess_restored',
    messId,
    restoredBy: callerUid,
    restoredAt,
    triggeredBy: callerUid,
  });

  return { success: true };
});
