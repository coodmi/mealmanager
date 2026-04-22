# Implementation Plan: Mess Chat Room

## Overview

Replace the static `ChatPage` placeholder with a fully functional real-time Firestore-backed group chat. The implementation is split into: data models (`ChatMessageModel`, `ReplyReference`), service layer (`ChatService`, `NotificationService`), extracted stateless widgets (`MessageBubble`, `PinnedMessageBanner`, `ReplyPreviewBar`, `QuickActionBar`, `SeenReceiptText`), the rebuilt `ChatPage`, unread badge integration in `DashboardPage`, and an Owner Announcement section in the Admin Panel.

## Tasks

- [x] 1. Create data model files
  - Create `lib/features/chat/data/models/chat_message_model.dart`
  - Implement `ReplyReference` class with `msgId`, `senderName`, `text` fields, `fromMap`, `toMap`
  - Implement `ChatMessageModel` class with all fields from the Firestore schema, `fromFirestore`, `toFirestore`, `copyWith`
  - _Requirements: 12.1, 12.2_

- [ ] 2. Write property tests for data model serialization
  - [ ]* 2.1 Write property test — Property 1: `ChatMessageModel` serialization round-trip
    - **Property 1: `ChatMessageModel` serialization round-trip**
    - For any valid `ChatMessageModel`, `fromFirestore(fakeDoc(m.toFirestore()))` must produce identical field values
    - **Validates: Requirement 12.3**

  - [ ]* 2.2 Write property test — Property 2: `ReplyReference` serialization round-trip
    - **Property 2: `ReplyReference` serialization round-trip**
    - For any valid `ReplyReference`, `fromMap(r.toMap())` must produce identical field values
    - **Validates: Requirement 12.4**

- [x] 3. Create `ChatService`
  - Create `lib/features/chat/services/chat_service.dart`
  - Implement `messagesStream(String messId)` — real-time stream ordered by `timestamp` ascending
  - Implement `pinnedMessageStream(String messId)` — stream of the single pinned message or null
  - Implement `unreadCountStream(String messId, String uid)` — stream of unread count
  - Implement `isActiveMember(String messId, String uid)` — validates membership
  - Implement `sendMessage(...)` — validates active membership, writes document with all required fields
  - Implement `markAsSeen(String messId, List<String> messageIds, String uid)` — batch `arrayUnion` update
  - Implement `pinMessage(String messId, String messageId)` — batch: clear old pin, set new pin
  - Implement `unpinMessage(String messId, String messageId)` — set `isPinned: false`
  - Implement `toggleNotificationPreference(String uid, bool enabled)` — update `users/{uid}/chatNotificationsEnabled`
  - Implement `getNotificationPreference(String uid)` — read preference, default `true`
  - _Requirements: 1.1, 2.2, 2.7, 3.2, 4.1, 4.5, 5.2, 5.5, 6.4, 6.5, 7.1, 11.1, 11.2_

- [x] 4. Create `NotificationService`
  - Create `lib/features/chat/services/notification_service.dart`
  - Implement `sendChatNotifications(...)` — fetch active members, exclude sender, check preferences, write notification docs in batches of 500
  - Notification document fields: `type: 'chat_message'`, `messId`, `senderName`, `text` (first 100 chars), `createdAt: FieldValue.serverTimestamp()`, `isRead: false`
  - _Requirements: 6.1, 6.2, 6.6_

- [ ] 5. Write property tests for service helpers
  - [ ]* 5.1 Write property test — Property 5: Unread count correctness
    - **Property 5: Unread count correctness**
    - For any list of `ChatMessageModel` and a `uid`, computed unread count equals messages where `seenBy` does not contain `uid`
    - **Validates: Requirement 7.1**

  - [ ]* 5.2 Write property test — Property 6: `markAsSeen` idempotence
    - **Property 6: `markAsSeen` idempotence**
    - Calling `markAsSeen` twice with same uid and message IDs produces identical `seenBy` arrays (no duplicates)
    - **Validates: Requirement 4.5**

  - [ ]* 5.3 Write property test — Property 7: Pin uniqueness invariant
    - **Property 7: Pin uniqueness invariant**
    - After any sequence of `pinMessage` calls, at most one message has `isPinned: true`
    - **Validates: Requirement 5.7**

  - [ ]* 5.4 Write property test — Property 8: Active member filter
    - **Property 8: Active member filter**
    - `filterActiveMembers` returns only entries where `isActive == true`; result count ≤ input count
    - **Validates: Requirement 11.1**

- [ ] 6. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [x] 7. Create `SeenReceiptText` widget
  - Create `lib/features/chat/presentation/widgets/seen_receipt_text.dart`
  - Implement `SeenReceiptText` stateless widget with `seenBy`, `activeMembers`, `currentUid` parameters
  - Logic: all active UIDs in `seenBy` → "Seen by Everyone"; some → "Seen by [name1], [name2]" + "and N more" if > 3; empty → `SizedBox.shrink()`
  - _Requirements: 4.2, 4.3, 4.4_

- [ ] 8. Write property tests for `SeenReceiptText`
  - [ ]* 8.1 Write property test — Property 3: All members seen → "Seen by Everyone"
    - **Property 3: `SeenReceiptText` all-seen display**
    - For any list of active member UIDs where all are in `seenBy`, display string equals "Seen by Everyone"
    - **Validates: Requirement 4.2**

  - [ ]* 8.2 Write property test — Property 4: Partial seen → starts with "Seen by" but not "Everyone"
    - **Property 4: `SeenReceiptText` partial-seen display**
    - For any non-empty proper subset of active UIDs in `seenBy`, display string starts with "Seen by" and ≠ "Seen by Everyone"
    - **Validates: Requirement 4.3**

- [x] 9. Create `PinnedMessageBanner` widget
  - Create `lib/features/chat/presentation/widgets/pinned_message_banner.dart`
  - Implement `PinnedMessageBanner` stateless widget with `message: ChatMessageModel?` parameter
  - Render "📌 [text truncated to 80 chars]" with light-green background; hidden when `message == null`
  - _Requirements: 5.3, 5.7_

- [x] 10. Create `ReplyPreviewBar` widget
  - Create `lib/features/chat/presentation/widgets/reply_preview_bar.dart`
  - Implement `ReplyPreviewBar` stateless widget with `replyTo: ReplyReference`, `onCancel` parameters
  - Render "Replying to [senderName]: [text preview truncated to 60 chars]" with a close icon
  - _Requirements: 3.1_

- [x] 11. Create `QuickActionBar` widget
  - Create `lib/features/chat/presentation/widgets/quick_action_bar.dart`
  - Implement `QuickActionBar` stateless widget with `onUpdateMeal`, `onBazarSchedule` callbacks
  - Render two `OutlinedButton` widgets: "Update Meal" and "Bazar Schedule"
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 12. Create `MessageBubble` widget
  - Create `lib/features/chat/presentation/widgets/message_bubble.dart`
  - Implement `MessageBubble` stateless widget with `message`, `currentUid`, `activeMembers`, `onSwipeReply`, `onLongPress`, `onTapReply` parameters
  - Owner announcement: full-width light-green card, app logo avatar (`assets/images/logo.png`), "Meal Manager" name
  - Own message: right-aligned green bubble, no avatar, `SeenReceiptText` below
  - Other message: left-aligned white card, initials `CircleAvatar`, sender name, optional green "Manager" badge
  - Reply block: if `replyTo != null`, render quoted block with left green border inside bubble
  - Swipe detection: `GestureDetector` `onHorizontalDragEnd` with `velocity.primaryVelocity > 300` triggers `onSwipeReply`
  - _Requirements: 1.3, 1.4, 1.5, 1.6, 3.3, 3.5, 4.4, 10.2_

- [ ] 13. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [x] 14. Rebuild `ChatPage`
  - Replace `lib/features/chat/presentation/pages/chat_page.dart` with full implementation
  - In `initState`: load `currentUid`, `messId`, `senderName`, `senderRole` from Firestore; subscribe to `messagesStream`, `pinnedMessageStream`; load notification preference; subscribe to active member count stream
  - State: `_replyTo`, `_notificationsEnabled`, `_currentUid`, `_messId`, `_messName`, `_memberCount`, `_senderRole`, `_senderName`, `_textController`, `_scrollController`, `_activeMembers`
  - Layout: `AppBar` (mess name + member count + back + bell toggle) → `PinnedMessageBanner` → `Expanded StreamBuilder ListView` → `QuickActionBar` → `ReplyPreviewBar` (conditional) → input row
  - `ListView.builder` renders `MessageBubble` for each message; auto-scrolls to bottom on new messages
  - Long-press on message: show bottom sheet with Pin/Unpin (manager only), Reply option
  - Swipe right on message: set `_replyTo` state
  - Tap quoted block: scroll to referenced message and briefly highlight it
  - Send button: calls `ChatService.sendMessage`, then `NotificationService.sendChatNotifications` as fire-and-forget
  - `markAsSeen` called on open and on scroll (debounced 500ms)
  - Bell toggle: calls `ChatService.toggleNotificationPreference`
  - Inactive member: disable input, show "You are not an active member" label
  - Wrap all Firestore operations in `try/catch`; surface errors via `ScaffoldMessenger` snack bars
  - _Requirements: 1.1, 1.2, 1.7, 1.8, 2.1, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.4, 4.1, 5.1, 5.4, 6.3, 6.4, 8.1, 9.1, 9.2, 9.3, 9.4, 9.5, 11.3, 11.4, 11.5_

- [x] 15. Integrate unread badge into `DashboardPage`
  - Add `_chatUnreadCount` state variable to `_DashboardPageState`
  - In `_initRealtimeDashboard`, add a stream subscription to `ChatService().unreadCountStream(messId, uid)` that updates `_chatUnreadCount`
  - Update the Chat `BottomNavigationBarItem` to wrap the icon with a `Badge` widget showing `_chatUnreadCount` when > 0, displaying "99+" when > 99
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 16. Add Owner Announcement to Admin Panel
  - In `lib/features/admin/admin_shell.dart` (or appropriate admin page), add an "Announcements" section
  - Implement a text input and "Send Announcement" button
  - On submit: validate current user role is `superAdmin` or `systemAdmin`; call `ChatService.sendMessage` with `senderRole: 'owner'`, `senderId: 'meal_manager'`, `senderName: 'Meal Manager'`, `isOwnerAnnouncement: true`
  - Fetch all mess IDs from Firestore and send the announcement to each mess's chat room
  - _Requirements: 10.1, 10.3_

- [ ] 17. Final Checkpoint — Ensure all tests pass, ask the user if questions arise.

## Notes

- Sub-tasks marked with `*` are optional and can be skipped for a faster MVP
- Property tests use the [glados](https://pub.dev/packages/glados) library; each test runs a minimum of 100 iterations
- `ChatService` and `NotificationService` have no Flutter dependency — they are pure Dart classes, making them straightforward to unit and property test
- `SeenReceiptText` display logic is a pure function — extract to a helper for easy property testing
- All write operations go through `ChatService`; the Firestore stream handles UI refresh automatically — no manual `setState` needed after writes
- Follow `AppColors.primaryGreen` / `AppColors.bgColor` / `AppColors.textDark` for all color usage
- Follow existing `StatefulWidget` + `StreamBuilder` pattern; no Provider/Bloc
- `markAsSeen` must use `FieldValue.arrayUnion` to prevent duplicate UIDs in `seenBy`
- Notification writes are fire-and-forget after message send — do not `await` them in the UI path
- The `Badge` widget is available in Flutter 3.x without additional packages
