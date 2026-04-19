import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

const TRACKED_SUBCOLLECTIONS = ['meals', 'expenses', 'transactions', 'withdrawals'];

export const updateLastActivity = onDocumentWritten(
  'messes/{messId}/{subcol}/{docId}',
  async (event) => {
    const { messId, subcol } = event.params;
    if (!TRACKED_SUBCOLLECTIONS.includes(subcol)) return;
    await db.collection('messes').doc(messId).update({
      lastActivityAt: FieldValue.serverTimestamp(),
    });
  }
);
