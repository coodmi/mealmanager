import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { batchDelete } from '../utils/batchDelete';
import { writeSysLog } from '../utils/logging';

const SUBCOLLECTIONS = [
  'meals',
  'expenses',
  'transactions',
  'withdrawals',
  'monthSummaries',
  'members',
  'joinRequests',
];

export const cleanupExpiredDeletedMesses = onSchedule('every 24 hours', async () => {
  const db = getFirestore();
  const cutoff = Timestamp.fromDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));

  const snap = await db.collection('deleted_messes').where('deletedAt', '<', cutoff).get();

  for (const doc of snap.docs) {
    const messId = doc.id;
    try {
      // Delete all subcollection docs under messes/{messId}
      for (const subcol of SUBCOLLECTIONS) {
        const subSnap = await db.collection('messes').doc(messId).collection(subcol).get();
        if (!subSnap.empty) {
          await batchDelete(db, subSnap);
        }
      }

      // Delete root messes/{messId} doc
      await db.collection('messes').doc(messId).delete();

      // Delete deleted_messes/{messId} doc
      await db.collection('deleted_messes').doc(messId).delete();

      // Log the permanent deletion
      await writeSysLog(db, {
        type: 'auto_deletion',
        target: messId,
        triggeredBy: 'scheduler',
      });
    } catch (err) {
      console.error(`cleanupExpiredDeletedMesses: failed to process mess ${messId}`, err);
    }
  }
});
