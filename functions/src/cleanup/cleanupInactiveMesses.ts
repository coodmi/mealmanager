import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { writeSysLog } from '../utils/logging';

export const cleanupInactiveMesses = onSchedule('every 24 hours', async () => {
  const db = getFirestore();
  const cutoffDate = new Date(Date.now() - 180 * 24 * 60 * 60 * 1000);
  const cutoff = Timestamp.fromDate(cutoffDate);

  // Collect inactive mess IDs (deduplicated)
  const inactiveMessIds = new Set<string>();

  // 1. Messes where lastActivityAt < cutoff
  try {
    const snap = await db.collection('messes').where('lastActivityAt', '<', cutoff).get();
    for (const doc of snap.docs) {
      inactiveMessIds.add(doc.id);
    }
  } catch (err) {
    console.error('cleanupInactiveMesses: lastActivityAt query failed', err);
  }

  // 2. Messes where createdAt < cutoff (fallback for docs missing lastActivityAt)
  try {
    const snap = await db.collection('messes').where('createdAt', '<', cutoff).get();
    for (const doc of snap.docs) {
      const data = doc.data();
      // Only include if lastActivityAt is missing/null (fallback case)
      if (data['lastActivityAt'] == null) {
        inactiveMessIds.add(doc.id);
      }
    }
  } catch (err) {
    console.error('cleanupInactiveMesses: createdAt fallback query failed', err);
  }

  // Process each inactive mess
  for (const messId of inactiveMessIds) {
    try {
      // Read the mess document
      const messRef = db.collection('messes').doc(messId);
      const messSnap = await messRef.get();

      if (!messSnap.exists) {
        // Already deleted or doesn't exist — skip
        continue;
      }

      const messData = messSnap.data() ?? {};

      // Write to deleted_messes/{messId}
      await db.collection('deleted_messes').doc(messId).set({
        ...messData,
        deletedBy: 'system',
        isDeleted: true,
        deletionReason: 'inactivity',
        deletedAt: FieldValue.serverTimestamp(),
      });

      // Batch-update all users where messId == messId
      const usersSnap = await db.collection('users').where('messId', '==', messId).get();
      const BATCH_LIMIT = 500;
      for (let i = 0; i < usersSnap.docs.length; i += BATCH_LIMIT) {
        const batch = db.batch();
        const chunk = usersSnap.docs.slice(i, i + BATCH_LIMIT);
        for (const userDoc of chunk) {
          batch.update(userDoc.ref, { messId: '', role: 'member' });
        }
        await batch.commit();
      }

      // Delete the messes/{messId} root doc
      await messRef.delete();

      // Log the auto-deletion
      await writeSysLog(db, {
        type: 'auto_deletion',
        target: messId,
        triggeredBy: 'scheduler',
        deletedBy: 'system',
        deletedAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error(`cleanupInactiveMesses: failed to process mess ${messId}`, err);
    }
  }
});
