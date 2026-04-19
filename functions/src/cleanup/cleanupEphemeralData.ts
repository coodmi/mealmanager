import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { batchDelete } from '../utils/batchDelete';
import { writeSysLog } from '../utils/logging';

export const cleanupEphemeralData = onSchedule('every 24 hours', async () => {
  const db = getFirestore();
  const cutoff = Timestamp.fromDate(new Date(Date.now() - 40 * 24 * 60 * 60 * 1000));

  // 1. adminNotifications — sentAt < 40 days ago
  try {
    const snap = await db
      .collection('adminNotifications')
      .where('sentAt', '<', cutoff)
      .get();
    const count = await batchDelete(db, snap);
    await writeSysLog(db, {
      type: 'auto_deletion',
      target: 'adminNotifications',
      count,
      triggeredBy: 'scheduler',
    });
  } catch (err) {
    console.error('cleanupEphemeralData: adminNotifications failed', err);
  }

  // 2. notifications (top-level) — createdAt < 40 days ago
  try {
    const snap = await db
      .collection('notifications')
      .where('createdAt', '<', cutoff)
      .get();
    const count = await batchDelete(db, snap);
    await writeSysLog(db, {
      type: 'auto_deletion',
      target: 'notifications',
      count,
      triggeredBy: 'scheduler',
    });
  } catch (err) {
    console.error('cleanupEphemeralData: notifications failed', err);
  }

  // 3. Per-mess subcollections: joinRequests and chatMessages
  let messIds: string[] = [];
  try {
    const messesSnap = await db.collection('messes').get();
    messIds = messesSnap.docs.map((d) => d.id);
  } catch (err) {
    console.error('cleanupEphemeralData: failed to fetch messes', err);
  }

  for (const messId of messIds) {
    // joinRequests — createdAt < 40 days ago
    try {
      const snap = await db
        .collection('messes')
        .doc(messId)
        .collection('joinRequests')
        .where('createdAt', '<', cutoff)
        .get();
      const count = await batchDelete(db, snap);
      await writeSysLog(db, {
        type: 'auto_deletion',
        target: `messes/${messId}/joinRequests`,
        count,
        triggeredBy: 'scheduler',
      });
    } catch (err) {
      console.error(`cleanupEphemeralData: messes/${messId}/joinRequests failed`, err);
    }

    // chatMessages — sentAt < 40 days ago
    try {
      const snap = await db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .where('sentAt', '<', cutoff)
        .get();
      const count = await batchDelete(db, snap);
      await writeSysLog(db, {
        type: 'auto_deletion',
        target: `messes/${messId}/chatMessages`,
        count,
        triggeredBy: 'scheduler',
      });
    } catch (err) {
      console.error(`cleanupEphemeralData: messes/${messId}/chatMessages failed`, err);
    }
  }
});
