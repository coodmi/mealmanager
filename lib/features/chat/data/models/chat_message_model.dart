import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyReference {
  final String msgId;
  final String senderName;
  final String text;

  const ReplyReference({
    required this.msgId,
    required this.senderName,
    required this.text,
  });

  factory ReplyReference.fromMap(Map<String, dynamic> map) {
    return ReplyReference(
      msgId: map['msgId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'msgId': msgId,
    'senderName': senderName,
    'text': text,
  };
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'manager' | 'member' | 'owner'
  final String text;
  final Timestamp timestamp;
  final ReplyReference? replyTo;
  final List<String> seenBy;
  final bool isPinned;
  final bool isOwnerAnnouncement;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.replyTo,
    required this.seenBy,
    required this.isPinned,
    required this.isOwnerAnnouncement,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final replyData = data['replyTo'] as Map<String, dynamic>?;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'member',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      replyTo: replyData != null ? ReplyReference.fromMap(replyData) : null,
      seenBy: List<String>.from(data['seenBy'] as List? ?? []),
      isPinned: data['isPinned'] as bool? ?? false,
      isOwnerAnnouncement: data['isOwnerAnnouncement'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'text': text,
    'timestamp': timestamp,
    'replyTo': replyTo?.toMap(),
    'seenBy': seenBy,
    'isPinned': isPinned,
    'isOwnerAnnouncement': isOwnerAnnouncement,
  };

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    Timestamp? timestamp,
    ReplyReference? replyTo,
    List<String>? seenBy,
    bool? isPinned,
    bool? isOwnerAnnouncement,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      seenBy: seenBy ?? this.seenBy,
      isPinned: isPinned ?? this.isPinned,
      isOwnerAnnouncement: isOwnerAnnouncement ?? this.isOwnerAnnouncement,
    );
  }
}
