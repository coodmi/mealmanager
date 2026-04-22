import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Real-time stream of messages ordered by timestamp asc ─────────────────
  Stream<List<ChatMessageModel>> messagesStream(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList(),
        );
  }

  // ── Real-time stream of the single pinned message ─────────────────────────
  Stream<ChatMessageModel?> pinnedMessageStream(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .where('isPinned', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return ChatMessageModel.fromFirestore(snap.docs.first);
        });
  }

  // ── Real-time stream of unread count for current user ─────────────────────
  Stream<int> unreadCountStream(String messId, String uid) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .snapshots()
        .map(
          (snap) => snap.docs.where((d) {
            final seenBy = List<String>.from(d.data()['seenBy'] as List? ?? []);
            return !seenBy.contains(uid);
          }).length,
        );
  }

  // ── Validate active membership ────────────────────────────────────────────
  Future<bool> isActiveMember(String messId, String uid) async {
    try {
      final doc = await _db
          .collection('messes')
          .doc(messId)
          .collection('members')
          .doc(uid)
          .get();
      return doc.exists && (doc.data()?['isActive'] as bool? ?? false);
    } catch (_) {
      return false;
    }
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String messId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    ReplyReference? replyTo,
    bool isOwnerAnnouncement = false,
  }) async {
    // Validate active membership (skip for owner announcements)
    if (!isOwnerAnnouncement) {
      final active = await isActiveMember(messId, senderId);
      if (!active) throw Exception('User is not an active member of this mess');
    }

    // Validate owner announcement role
    if (isOwnerAnnouncement && senderRole != 'owner') {
      throw Exception('Only app owners can send announcements');
    }

    await _db.collection('messes').doc(messId).collection('chatMessages').add({
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': replyTo?.toMap(),
      'seenBy': [senderId],
      'isPinned': false,
      'isOwnerAnnouncement': isOwnerAnnouncement,
    });
  }

  // ── Mark messages as seen ─────────────────────────────────────────────────
  Future<void> markAsSeen(
    String messId,
    List<String> messageIds,
    String uid,
  ) async {
    if (messageIds.isEmpty) return;
    // Process in batches of 500
    for (int i = 0; i < messageIds.length; i += 500) {
      final batch = _db.batch();
      final chunk = messageIds.skip(i).take(500);
      for (final msgId in chunk) {
        batch.update(
          _db
              .collection('messes')
              .doc(messId)
              .collection('chatMessages')
              .doc(msgId),
          {
            'seenBy': FieldValue.arrayUnion([uid]),
          },
        );
      }
      await batch.commit();
    }
  }

  // ── Pin a message (clears previous pin in same batch) ─────────────────────
  Future<void> pinMessage(String messId, String messageId) async {
    final batch = _db.batch();

    // Clear existing pinned message
    final existing = await _db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .where('isPinned', isEqualTo: true)
        .get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isPinned': false});
    }

    // Set new pin
    batch.update(
      _db
          .collection('messes')
          .doc(messId)
          .collection('chatMessages')
          .doc(messageId),
      {'isPinned': true},
    );

    await batch.commit();
  }

  // ── Unpin a message ───────────────────────────────────────────────────────
  Future<void> unpinMessage(String messId, String messageId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('chatMessages')
        .doc(messageId)
        .update({'isPinned': false});
  }

  // ── Toggle notification preference ───────────────────────────────────────
  Future<void> toggleNotificationPreference(String uid, bool enabled) async {
    await _db.collection('users').doc(uid).update({
      'chatNotificationsEnabled': enabled,
    });
  }

  // ── Get notification preference (default true) ────────────────────────────
  Future<bool> getNotificationPreference(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['chatNotificationsEnabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  // ── Get active members for a mess ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getActiveMembers(String messId) async {
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ── Stream of active member count ─────────────────────────────────────────
  Stream<int> activeMemberCountStream(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
