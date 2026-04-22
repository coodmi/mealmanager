import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/pinned_message_banner.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/quick_action_bar.dart';
import '../../../bazar/presentation/pages/bazar_schedule_page.dart';
import '../../../meal/presentation/pages/meal_page_working.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chatService = ChatService();
  final _notifService = ChatNotificationService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String _currentUid = '';
  String _messId = '';
  String _messName = '';
  String _senderName = '';
  String _senderRole = 'member';
  int _memberCount = 0;
  bool _notificationsEnabled = true;
  bool _isActiveMember = true;
  bool _isLoading = true;

  ReplyReference? _replyTo;
  List<Map<String, dynamic>> _activeMembers = [];
  List<ChatMessageModel> _messages = [];
  ChatMessageModel? _pinnedMessage;
  String? _highlightedMsgId;

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _seenDebounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _seenDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _currentUid = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .get();
      final data = userDoc.data() ?? {};
      _messId = data['messId'] as String? ?? '';
      _senderName = data['name'] as String? ?? 'Member';
      _senderRole = data['role'] as String? ?? 'member';

      if (_messId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Load mess name
      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .get();
      _messName = messDoc.data()?['name'] as String? ?? 'Mess Chat';

      // Check active membership
      _isActiveMember = await _chatService.isActiveMember(_messId, _currentUid);

      // Load notification preference
      _notificationsEnabled = await _chatService.getNotificationPreference(
        _currentUid,
      );

      // Load active members
      _activeMembers = await _chatService.getActiveMembers(_messId);

      if (mounted) setState(() => _isLoading = false);

      // Subscribe to messages stream
      _subs.add(
        _chatService.messagesStream(_messId).listen((msgs) {
          if (!mounted) return;
          setState(() => _messages = msgs);
          _scrollToBottom();
          _debouncedMarkAsSeen();
        }),
      );

      // Subscribe to pinned message stream
      _subs.add(
        _chatService.pinnedMessageStream(_messId).listen((pinned) {
          if (!mounted) return;
          setState(() => _pinnedMessage = pinned);
        }),
      );

      // Subscribe to member count stream
      _subs.add(
        _chatService.activeMemberCountStream(_messId).listen((count) {
          if (!mounted) return;
          setState(() => _memberCount = count);
        }),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _debouncedMarkAsSeen() {
    _seenDebounce?.cancel();
    _seenDebounce = Timer(
      const Duration(milliseconds: 500),
      _markVisibleAsSeen,
    );
  }

  Future<void> _markVisibleAsSeen() async {
    if (_messId.isEmpty || _currentUid.isEmpty) return;
    final unread = _messages
        .where((m) => !m.seenBy.contains(_currentUid))
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    await _chatService.markAsSeen(_messId, unread, _currentUid);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final reply = _replyTo;
    setState(() => _replyTo = null);

    try {
      await _chatService.sendMessage(
        messId: _messId,
        senderId: _currentUid,
        senderName: _senderName,
        senderRole: _senderRole,
        text: text,
        replyTo: reply,
      );
      // Fire-and-forget notifications
      unawaited(
        _notifService.sendChatNotifications(
          messId: _messId,
          senderUid: _currentUid,
          senderName: _senderName,
          text: text,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _textController.text = text; // restore text
      }
    }
  }

  void _scrollToMessage(String msgId) {
    final index = _messages.indexWhere((m) => m.id == msgId);
    if (index < 0) return;
    final itemHeight = 80.0;
    _scrollController.animateTo(
      index * itemHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _highlightedMsgId = msgId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMsgId = null);
    });
  }

  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primaryGreen),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _replyTo = ReplyReference(
                    msgId: message.id,
                    senderName: message.senderName,
                    text: message.text,
                  );
                });
              },
            ),
            if (_senderRole == 'manager' && !message.isOwnerAnnouncement) ...[
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: AppColors.primaryGreen,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    if (message.isPinned) {
                      await _chatService.unpinMessage(_messId, message.id);
                    } else {
                      await _chatService.pinMessage(_messId, message.id);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FFF7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_messId.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Mess Chat'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'You are not in a mess yet.\nJoin or create a mess to chat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _messName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$_memberCount members',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              size: 22,
            ),
            tooltip: _notificationsEnabled
                ? 'Notifications ON'
                : 'Notifications OFF',
            onPressed: () async {
              final newVal = !_notificationsEnabled;
              setState(() => _notificationsEnabled = newVal);
              await _chatService.toggleNotificationPreference(
                _currentUid,
                newVal,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned message banner
          PinnedMessageBanner(
            message: _pinnedMessage,
            onTap: _pinnedMessage != null
                ? () => _scrollToMessage(_pinnedMessage!.id)
                : null,
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return MessageBubble(
                        key: ValueKey(msg.id),
                        message: msg,
                        currentUid: _currentUid,
                        activeMembers: _activeMembers,
                        isHighlighted: _highlightedMsgId == msg.id,
                        onSwipeReply: () {
                          setState(() {
                            _replyTo = ReplyReference(
                              msgId: msg.id,
                              senderName: msg.senderName,
                              text: msg.text,
                            );
                          });
                        },
                        onLongPress: () => _showMessageOptions(msg),
                        onTapReply: _scrollToMessage,
                      );
                    },
                  ),
          ),

          // Quick action bar
          QuickActionBar(
            onUpdateMeal: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealPageWorking()),
            ),
            onBazarSchedule: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BazarSchedulePage()),
            ),
          ),

          // Reply preview bar
          if (_replyTo != null)
            ReplyPreviewBar(
              replyTo: _replyTo!,
              onCancel: () => setState(() => _replyTo = null),
            ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: !_isActiveMember
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'You are not an active member of this mess',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            : Row(
                children: [
                  // Emoji button
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: Colors.grey.shade400,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FFF7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _textController.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _textController.text.trim().isEmpty
                            ? Colors.grey.shade300
                            : AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
