import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { batchDelete } from '../utils/batchDelete';
import { writeSysLog } from '../utils/logging';

const SUBCOLLECTIONS = ['meals', 'expenses', 'transactions', 'withdrawals'] as const;

export const cleanupMessOperationalData = onSchedule('every 24 hours', async (_event) => {
  const db = getFirestore();
  const cutoff = Timestamp.fromDate(new Date(Date.now() - 180 * 24 * 60 * 60 * 1000));

  const messesSnap = await db.collection('messes').get();

  for (const messDoc of messesSnap.docs) {
    const messId = messDoc.id;

    for (const subcol of SUBCOLLECTIONS) {
      try {
        const snap = await db
          .collection('messes')
          .doc(messId)
          .collection(subcol)
          .where('date', '<', cutoff)
          .get();

        const count = await batchDelete(db, snap);

        await writeSysLog(db, {
          type: 'auto_deletion',
          target: `messes/${messId}/${subcol}`,
          messId,
          count,
          triggeredBy: 'scheduler',
        });
      } catch (err) {
        console.error(`cleanupMessOperationalData: error on messes/${messId}/${subcol}:`, err);
      }
    }
  }
});
