# Design Document: Mess Chat Room

## Overview

This document describes the technical architecture for the Mess Chat Room feature. The implementation replaces the existing static `ChatPage` placeholder with a fully functional real-time group chat backed by Firestore. The design follows the existing app patterns: `StatefulWidget` + `StreamBuilder`, `AppColors` constants, no Provider/Bloc, and direct Firestore access through a dedicated service class.

---

## Architecture

### Layer Structure

```
lib/features/chat/
├── data/
│   └── models/
│       └── chat_message_model.dart       # ChatMessageModel + ReplyReference
├── services/
│   └── chat_service.dart                 # All Firestore read/write logic
└── presentation/
    ├── pages/
    │   └── chat_page.dart                # Rebuilt full chat UI (replaces placeholder)
    └── widgets/
        ├── message_bubble.dart           # Renders a single message (own/other/announcement)
        ├── reply_preview_bar.dart        # "Replying to X: ..." bar above input
        ├── pinned_message_banner.dart    # Banner below header for pinned message
        ├── quick_action_bar.dart         # "Update Meal" + "Bazar Schedule" buttons
        └── seen_receipt_text.dart        # "Seen by X, Y" / "Seen by Everyone"
```

### Firestore Collections

```
messes/{messId}/chatMessages/{msgId}
  senderId:            String
  senderName:          String
  senderRole:          'manager' | 'member' | 'owner'
  text:                String
  timestamp:           Timestamp
  replyTo:             { msgId: String, senderName: String, text: String } | null
  seenBy:              String[]   (array of UIDs)
  isPinned:            bool
  isOwnerAnnouncement: bool

users/{uid}/
  chatNotificationsEnabled: bool   (default true)

users/{uid}/notifications/{docId}
  type:        'chat_message'
  messId:      String
  senderName:  String
  text:        String   (first 100 chars)
  createdAt:   Timestamp
  isRead:      bool
```

---

## Data Models

### `ChatMessageModel`

```dart
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;   // 'manager' | 'member' | 'owner'
  final String text;
  final Timestamp timestamp;
  final ReplyReference? replyTo;
  final List<String> seenBy;
  final bool isPinned;
  final bool isOwnerAnnouncement;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
  ChatMessageModel copyWith({...});
}
```

### `ReplyReference`

```dart
class ReplyReference {
  final String msgId;
  final String senderName;
  final String text;

  factory ReplyReference.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
}
```

---

## Service Layer: `ChatService`

All Firestore operations are encapsulated in `ChatService`. It has no Flutter dependency, making it straightforward to unit test.

### Key Methods

```dart
class ChatService {
  // Real-time stream of messages for a mess, ordered by timestamp asc
  Stream<List<ChatMessageModel>> messagesStream(String messId);

  // Real-time stream of the single pinned message (null if none)
  Stream<ChatMessageModel?> pinnedMessageStream(String messId);

  // Real-time stream of unread count for current user
  Stream<int> unreadCountStream(String messId, String uid);

  // Send a new message; validates active membership first
  Future<void> sendMessage({
    required String messId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    ReplyReference? replyTo,
  });

  // Mark all provided message IDs as seen by uid
  Future<void> markAsSeen(String messId, List<String> messageIds, String uid);

  // Pin a message (clears previous pin in same batch)
  Future<void> pinMessage(String messId, String messageId);

  // Unpin a message
  Future<void> unpinMessage(String messId, String messageId);

  // Toggle notification preference for a user
  Future<void> toggleNotificationPreference(String uid, bool enabled);

  // Get notification preference (defaults to true)
  Future<bool> getNotificationPreference(String uid);

  // Validate active membership
  Future<bool> isActiveMember(String messId, String uid);
}
```

### `NotificationService` (within `chat_service.dart` or separate)

```dart
class NotificationService {
  // Write chat_message notification docs for all eligible members
  Future<void> sendChatNotifications({
    required String messId,
    required String senderUid,
    required String senderName,
    required String text,
    required List<String> activeMemberUids,
  });
}
```

---

## UI Components

### `ChatPage` (rebuilt)

`ChatPage` is a `StatefulWidget`. On `initState` it:
1. Loads current user UID, messId, userName, and role from Firestore.
2. Loads active member count via a stream.
3. Subscribes to `ChatService.messagesStream` via `StreamBuilder`.
4. Subscribes to `ChatService.pinnedMessageStream`.
5. Subscribes to `ChatService.unreadCountStream` (used by `DashboardPage` badge).
6. Loads `chatNotificationsEnabled` preference.

State variables:
- `_replyTo: ReplyReference?` — current reply target
- `_notificationsEnabled: bool`
- `_currentUid: String`
- `_messId: String`
- `_messName: String`
- `_memberCount: int`
- `_senderRole: String`
- `_senderName: String`
- `_textController: TextEditingController`
- `_scrollController: ScrollController`

Layout (top to bottom):
1. `AppBar` — mess name + member count subtitle + back arrow + bell toggle
2. `PinnedMessageBanner` — shown only when a pinned message exists
3. `Expanded` `StreamBuilder<List<ChatMessageModel>>` → `ListView.builder` of `MessageBubble`
4. `QuickActionBar` — "Update Meal" + "Bazar Schedule"
5. `ReplyPreviewBar` — shown only when `_replyTo != null`
6. Message input row — `TextField` + send `IconButton`

### `MessageBubble`

Stateless widget. Parameters: `message`, `currentUid`, `activeMembers`, `onSwipeReply`, `onLongPress`, `onTapReply`.

Rendering logic:
- `isOwnerAnnouncement == true` → full-width light-green card, app logo avatar, "Meal Manager" name
- `senderId == currentUid` → right-aligned green bubble, no avatar
- otherwise → left-aligned white card, initials avatar, sender name, optional Manager badge

Reply block: if `replyTo != null`, renders a quoted block with left green border (`AppColors.primaryGreen`) inside the bubble.

Seen receipt: rendered below the bubble only when `senderId == currentUid`, using `SeenReceiptText`.

Swipe detection: `GestureDetector` with `onHorizontalDragEnd` checking `velocity.primaryVelocity > 300` for right swipe.

### `PinnedMessageBanner`

Stateless widget. Parameters: `message: ChatMessageModel?`. Renders a tappable banner: `"📌 ${message.text.truncate(80)}"` with a light-green background. Hidden when `message == null`.

### `ReplyPreviewBar`

Stateless widget. Parameters: `replyTo: ReplyReference`, `onCancel`. Renders "Replying to [name]: [preview]" with a close icon.

### `QuickActionBar`

Stateless widget. Two `OutlinedButton` widgets: "Update Meal" and "Bazar Schedule". Tapping navigates using the existing page references.

### `SeenReceiptText`

Stateless widget. Parameters: `seenBy: List<String>`, `activeMembers: List<MemberModel>`. Computes display string:
- All active UIDs in `seenBy` → "Seen by Everyone"
- Some UIDs → "Seen by [name1], [name2]" + "and N more" if > 3
- Empty → no widget

---

## Unread Badge Integration

`DashboardPage` already holds stream subscriptions in `_subs`. A new subscription is added:

```dart
_subs.add(
  ChatService().unreadCountStream(messId, uid).listen((count) {
    if (!mounted) return;
    setState(() => _chatUnreadCount = count);
  }),
);
```

The bottom nav `BottomNavigationBarItem` for Chat is wrapped with a `Badge` widget (Flutter 3.x built-in) showing `_chatUnreadCount` when > 0, and "99+" when > 99.

---

## Seen Receipt Update Strategy

To avoid excessive Firestore writes, `markAsSeen` is called:
1. When `ChatPage` first opens — marks all currently loaded messages.
2. When the `ListView` scrolls and new messages become visible — debounced with a 500ms timer.
3. Only for messages not already containing `currentUid` in `seenBy`.

Batch writes are used when marking more than one message at a time (up to 500 per batch).

---

## Pin Message Flow

1. User long-presses a `MessageBubble` → `onLongPress` callback fires.
2. `ChatPage` shows a `showModalBottomSheet` or `showMenu` with options.
3. If `senderRole == 'manager'`: show "Pin" or "Unpin" based on `message.isPinned`.
4. On confirm: call `ChatService.pinMessage` or `ChatService.unpinMessage`.
5. `pinMessage` uses a `WriteBatch`:
   - Query for existing pinned message → set `isPinned: false`.
   - Set `isPinned: true` on the target message.

---

## Owner Announcement (Admin Panel)

The Admin Panel (existing `AdminShell`) gains a new "Send Announcement" section. It:
1. Presents a text input for the announcement message.
2. On submit, calls `ChatService.sendMessage` with `senderRole: 'owner'`, `senderId: 'meal_manager'`, `senderName: 'Meal Manager'`, `isOwnerAnnouncement: true`.
3. The service validates that the current user's Firestore role is `superAdmin` or `systemAdmin` before writing.

---

## Notification Flow

When `ChatService.sendMessage` succeeds:
1. Fetch all active member UIDs from `messes/{messId}/members` where `isActive: true`.
2. Exclude the sender's UID.
3. For each remaining UID, check `users/{uid}/chatNotificationsEnabled` (default `true`).
4. Write notification documents in batches of 500.

This is done as a fire-and-forget call after the message write succeeds, so it does not block the UI.

---

## Correctness Properties

### Property 1: `ChatMessageModel` serialization round-trip
For any valid `ChatMessageModel` instance `m`, `ChatMessageModel.fromFirestore(fakeDoc(m.toFirestore()))` produces an object with identical field values.
- Validates: Requirement 12.3

### Property 2: `ReplyReference` serialization round-trip
For any valid `ReplyReference` instance `r`, `ReplyReference.fromMap(r.toMap())` produces an object with identical field values.
- Validates: Requirement 12.4

### Property 3: `SeenReceiptText` display logic — all members seen
For any list of active member UIDs where all UIDs are present in `seenBy`, the computed display string equals "Seen by Everyone".
- Validates: Requirement 4.2

### Property 4: `SeenReceiptText` display logic — partial seen
For any non-empty subset of active member UIDs present in `seenBy` (but not all), the computed display string starts with "Seen by" and does not equal "Seen by Everyone".
- Validates: Requirement 4.3

### Property 5: Unread count correctness
For any list of `ChatMessageModel` instances and a given `uid`, the computed unread count equals the number of messages whose `seenBy` array does not contain `uid`.
- Validates: Requirement 7.1

### Property 6: `markAsSeen` idempotence
Calling `markAsSeen` twice with the same `uid` and message IDs results in `seenBy` arrays that are identical after both calls (no duplicate UIDs).
- Validates: Requirement 4.5

### Property 7: Pin uniqueness invariant
After any sequence of `pinMessage` calls, at most one message in the Chat_Room has `isPinned: true`.
- Validates: Requirement 5.7

### Property 8: Active member filter
For any list of member maps, `filterActiveMembers` returns only entries where `isActive == true`, and the result count is less than or equal to the input count.
- Validates: Requirement 11.1

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Firestore stream error | Show error banner; retain last messages |
| Send message fails | Show snack bar; retain typed text |
| Pin/unpin fails | Show snack bar |
| Inactive member tries to send | Disable input; show "not an active member" label |
| Non-manager tries to pin | Pin option not shown in context menu |
| Non-admin tries to send announcement | `ChatService` rejects write; returns error |

---

## Dependencies

No new packages required. Uses existing:
- `cloud_firestore`
- `firebase_auth`
- Flutter built-in `Badge` widget (Flutter 3.x)
- `AppColors`, `MemberModel` from existing codebase
