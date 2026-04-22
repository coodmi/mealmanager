import 'package:cloud_firestore/cloud_firestore.dart';

class ChatNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Writes chat_message notification docs for all eligible members.
  /// Fire-and-forget — do not await in UI path.
  Future<void> sendChatNotifications({
    required String messId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    try {
      // Get all active members
      final membersSnap = await _db
          .collection('messes')
          .doc(messId)
          .collection('members')
          .where('isActive', isEqualTo: true)
          .get();

      final recipientUids = membersSnap.docs
          .map((d) => d.id)
          .where((uid) => uid != senderUid)
          .toList();

      if (recipientUids.isEmpty) return;

      // Check notification preferences and write in batches of 500
      final textPreview = text.length > 100 ? text.substring(0, 100) : text;

      for (int i = 0; i < recipientUids.length; i += 500) {
        final batch = _db.batch();
        final chunk = recipientUids.skip(i).take(500);

        for (final uid in chunk) {
          // Check preference
          final userDoc = await _db.collection('users').doc(uid).get();
          final notifEnabled =
              userDoc.data()?['chatNotificationsEnabled'] as bool? ?? true;
          if (!notifEnabled) continue;

          final notifRef = _db
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc();
          batch.set(notifRef, {
            'type': 'chat_message',
            'messId': messId,
            'senderName': senderName,
            'text': textPreview,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }

        await batch.commit();
      }
    } catch (_) {
      // Fire-and-forget — swallow errors silently
    }
  }
}
