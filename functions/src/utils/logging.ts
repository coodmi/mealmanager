import { Firestore, FieldValue } from 'firebase-admin/firestore';

/**
 * Writes a structured entry to the `systemLogs` collection.
 * The `createdAt` field is set server-side via FieldValue.serverTimestamp().
 */
export async function writeSysLog(
  db: Firestore,
  entry: {
    type: string;
    target?: string;
    messId?: string;
    count?: number;
    deletedBy?: string;
    restoredBy?: string;
    deletedAt?: FieldValue;
    restoredAt?: FieldValue;
    triggeredBy: string;
  },
): Promise<void> {
  await db.collection('systemLogs').add({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}
