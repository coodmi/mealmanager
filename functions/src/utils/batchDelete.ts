import { Firestore, QuerySnapshot } from 'firebase-admin/firestore';

const BATCH_SIZE = 500;

/**
 * Deletes all documents in a QuerySnapshot in batches of ≤500.
 * Returns the total number of documents deleted.
 */
export async function batchDelete(
  db: Firestore,
  snap: QuerySnapshot,
): Promise<number> {
  const docs = snap.docs;
  let deleted = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }

  return deleted;
}
