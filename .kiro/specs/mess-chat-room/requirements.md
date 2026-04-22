# Requirements Document

## Introduction

The Mess Chat Room feature adds a real-time group messaging channel to every mess in the app. Each mess has exactly one shared chat room where all active members can send and receive messages. The feature replaces the existing static placeholder `ChatPage` with a fully functional Firestore-backed group chat. It includes reply threading, message pinning, seen receipts, owner announcements from the Admin Panel, quick-action shortcuts, per-user push notification preferences, and an unread badge on the bottom navigation tab.

## Glossary

- **Chat_Room**: The single shared group messaging channel belonging to one mess, backed by the `messes/{messId}/chatMessages` Firestore collection.
- **Message**: A document in `messes/{messId}/chatMessages/{msgId}` containing text, sender metadata, timestamp, reply reference, seen list, and optional flags.
- **Sender**: The authenticated user who authored a message.
- **Member**: An active user belonging to a mess, stored in `messes/{messId}/members/{uid}` with `isActive: true`.
- **Manager**: A mess member whose role is `'manager'` in the mess document.
- **Owner_Announcement**: A special message with `isOwnerAnnouncement: true` and `senderRole: 'owner'`, sent exclusively from the Admin Panel by a `superAdmin` or `systemAdmin` user.
- **Meal_Manager**: The display name used for Owner_Announcement messages; the avatar is the app logo (`assets/images/logo.png`).
- **Pinned_Message**: The single message in a Chat_Room that has `isPinned: true`; only the Manager may set or clear it.
- **Reply**: A message that references another message via the `replyTo` field containing `{msgId, senderName, text}`.
- **Seen_Receipt**: The `seenBy` array on a Message document, containing the UIDs of members who have viewed the message.
- **Notification_Preference**: A per-user boolean stored in `users/{uid}` as `chatNotificationsEnabled` (default `true`).
- **Unread_Count**: The number of messages in the Chat_Room whose `seenBy` array does not contain the current user's UID.
- **Quick_Action**: A shortcut button above the message input that navigates to another feature page (Update Meal or Bazar Schedule).
- **Chat_Service**: The Dart service class responsible for all Firestore read/write operations for the Chat_Room.
- **Notification_Service**: The Dart service class responsible for writing push notification documents to `users/{uid}/notifications`.

---

## Requirements

### Requirement 1: Real-Time Message Display

**User Story:** As a mess member, I want to see all group messages in real-time, so that I can stay up to date with my mess conversations without refreshing.

#### Acceptance Criteria

1. WHEN the Chat_Room page is opened, THE Chat_Service SHALL subscribe to a real-time Firestore stream on `messes/{messId}/chatMessages` ordered by `timestamp` ascending.
2. WHEN a new Message document is written to Firestore, THE Chat_Room SHALL display the new message within the visible message list without requiring a manual refresh.
3. THE Chat_Room SHALL render messages sent by the current user on the right side with a green-tinted bubble and no avatar.
4. THE Chat_Room SHALL render messages sent by other members on the left side with a white card, a circular avatar showing the sender's initials, the sender's name, and the message timestamp.
5. WHEN a Message has `senderRole: 'manager'`, THE Chat_Room SHALL display a green "Manager" badge next to the sender's name.
6. WHEN a Message has `isOwnerAnnouncement: true`, THE Chat_Room SHALL render it as a visually distinct highlighted card with a light-green background, the Meal_Manager display name, and the app logo as the avatar.
7. WHEN the Chat_Room page is opened, THE Chat_Room SHALL automatically scroll to the most recent message.
8. IF the Firestore stream emits an error, THEN THE Chat_Room SHALL display an error banner and retain the last successfully loaded messages.

---

### Requirement 2: Send Messages

**User Story:** As an active mess member, I want to type and send messages to the group chat, so that I can communicate with my mess.

#### Acceptance Criteria

1. THE Chat_Room SHALL display a text input field and a send button at the bottom of the screen.
2. WHEN the send button is tapped and the input field contains at least one non-whitespace character, THE Chat_Service SHALL write a new Message document to `messes/{messId}/chatMessages` with `senderId`, `senderName`, `senderRole`, `text`, `timestamp: FieldValue.serverTimestamp()`, `seenBy: [currentUid]`, `replyTo: null`, `isPinned: false`, and `isOwnerAnnouncement: false`.
3. WHEN a Message is successfully sent, THE Chat_Room SHALL clear the text input field.
4. IF the text input field is empty or contains only whitespace, THEN THE Chat_Room SHALL disable the send button.
5. WHILE the current user is not an active Member of the mess, THE Chat_Room SHALL display the input area as disabled with a label "You are not an active member".
6. IF the Firestore write fails, THEN THE Chat_Service SHALL surface an error message via a snack bar without clearing the typed text.
7. THE Chat_Service SHALL validate that the current user's UID exists in `messes/{messId}/members` with `isActive: true` before writing a Message document.

---

### Requirement 3: Reply to Messages

**User Story:** As a mess member, I want to reply to a specific message by swiping on it, so that conversations stay contextual and easy to follow.

#### Acceptance Criteria

1. WHEN a member swipes right on any Message bubble, THE Chat_Room SHALL enter reply mode and display a reply preview bar above the input field showing "Replying to [senderName]: [text preview truncated to 60 characters]".
2. WHILE in reply mode, THE Chat_Room SHALL include the `replyTo: {msgId, senderName, text}` field in the next sent Message document.
3. WHEN a Message with a non-null `replyTo` field is rendered, THE Chat_Room SHALL display a quoted block with a left green border inside the message bubble showing the original sender's name and a text preview.
4. WHEN the cancel button on the reply preview bar is tapped, THE Chat_Room SHALL exit reply mode and clear the `replyTo` reference.
5. WHEN a member taps the quoted block inside a message bubble, THE Chat_Room SHALL scroll to and briefly highlight the original referenced message.

---

### Requirement 4: Seen Receipts

**User Story:** As a mess member, I want to know who has seen my messages, so that I can confirm my messages have been read.

#### Acceptance Criteria

1. WHEN the Chat_Room page is opened or scrolled, THE Chat_Service SHALL update the `seenBy` array of all visible messages that do not already contain the current user's UID by appending the UID using `FieldValue.arrayUnion`.
2. WHEN all active Members' UIDs are present in a Message's `seenBy` array, THE Chat_Room SHALL display "Seen by Everyone" below that message.
3. WHEN some but not all active Members have seen a Message, THE Chat_Room SHALL display "Seen by [name1], [name2]" listing up to 3 names, followed by "and N more" if there are additional viewers.
4. THE Chat_Room SHALL only display seen receipt text for messages sent by the current user.
5. THE Chat_Service SHALL use `FieldValue.arrayUnion` to update `seenBy` to prevent duplicate UID entries.

---

### Requirement 5: Pinned Message

**User Story:** As a mess manager, I want to pin one important message at the top of the chat, so that all members can see critical information easily.

#### Acceptance Criteria

1. WHEN the Manager long-presses a Message, THE Chat_Room SHALL display a context menu with a "Pin Message" option.
2. WHEN the Manager selects "Pin Message", THE Chat_Service SHALL set `isPinned: true` on the selected Message document and set `isPinned: false` on any previously pinned Message document in the same Chat_Room using a Firestore batch write.
3. WHEN a Message with `isPinned: true` exists in the Chat_Room, THE Chat_Room SHALL display a pinned message banner below the header showing "📌 [message text preview truncated to 80 characters]".
4. WHEN the Manager long-presses the currently pinned Message, THE Chat_Room SHALL display a context menu with an "Unpin Message" option.
5. WHEN the Manager selects "Unpin Message", THE Chat_Service SHALL set `isPinned: false` on the Message document.
6. IF the current user is not the Manager, THEN THE Chat_Room SHALL not display pin or unpin options in the context menu.
7. THE Chat_Room SHALL display at most one pinned message banner at a time.

---

### Requirement 6: Push Notifications

**User Story:** As a mess member, I want to receive push notifications for new chat messages, so that I stay informed even when the app is in the background.

#### Acceptance Criteria

1. WHEN a Message is successfully written to Firestore, THE Notification_Service SHALL write a notification document to `users/{uid}/notifications` for each active Member whose UID is not the sender's UID and whose `chatNotificationsEnabled` preference is `true`.
2. THE Notification_Service SHALL write notification documents with fields: `type: 'chat_message'`, `messId`, `senderName`, `text` (first 100 characters of message text), `createdAt: FieldValue.serverTimestamp()`, `isRead: false`.
3. THE Chat_Room header SHALL display a bell icon toggle button that reflects the current user's `chatNotificationsEnabled` preference.
4. WHEN the bell icon toggle is tapped, THE Chat_Service SHALL update `users/{uid}/chatNotificationsEnabled` to the opposite boolean value in Firestore.
5. THE Chat_Room SHALL default `chatNotificationsEnabled` to `true` for users who do not have the field set.
6. WHERE the mess has more than 50 active members, THE Notification_Service SHALL write notification documents in batches of 500 using Firestore batch writes.

---

### Requirement 7: Unread Message Count Badge

**User Story:** As a mess member, I want to see an unread message count badge on the chat tab, so that I know when there are new messages without opening the chat.

#### Acceptance Criteria

1. THE Dashboard_Page SHALL display a numeric badge on the Chat tab in the bottom navigation bar showing the count of messages in the Chat_Room whose `seenBy` array does not contain the current user's UID.
2. WHEN the unread count is zero, THE Dashboard_Page SHALL not display a badge on the Chat tab.
3. WHEN the unread count exceeds 99, THE Dashboard_Page SHALL display "99+" on the badge.
4. THE Dashboard_Page SHALL update the unread badge count in real-time using a Firestore stream subscription.

---

### Requirement 8: Quick Action Shortcuts

**User Story:** As a mess member, I want quick-action buttons above the message input, so that I can navigate to Update Meal and Bazar Schedule without leaving the chat context.

#### Acceptance Criteria

1. THE Chat_Room SHALL display two quick-action shortcut buttons above the message input bar: "Update Meal" and "Bazar Schedule".
2. WHEN the "Update Meal" button is tapped, THE Chat_Room SHALL navigate to the meal update page.
3. WHEN the "Bazar Schedule" button is tapped, THE Chat_Room SHALL navigate to the Bazar Schedule page.

---

### Requirement 9: Chat Room Header

**User Story:** As a mess member, I want to see the mess name and member count in the chat header, so that I know which mess chat I am in.

#### Acceptance Criteria

1. THE Chat_Room header SHALL display the mess name in bold as the title.
2. THE Chat_Room header SHALL display the count of active Members as a subtitle in the format "N members".
3. THE Chat_Room header SHALL display a back arrow that navigates to the previous screen.
4. THE Chat_Room header SHALL display the notification bell toggle on the right side of the header.
5. WHEN the active member count changes in Firestore, THE Chat_Room header SHALL update the member count in real-time.

---

### Requirement 10: Owner Announcements

**User Story:** As a superAdmin or systemAdmin, I want to send highlighted announcements to all mess chat rooms from the Admin Panel, so that I can communicate important updates to all users.

#### Acceptance Criteria

1. WHEN a superAdmin or systemAdmin sends an announcement from the Admin Panel, THE Chat_Service SHALL write a Message document with `senderId: 'meal_manager'`, `senderName: 'Meal Manager'`, `senderRole: 'owner'`, `isOwnerAnnouncement: true`, and the provided text.
2. THE Chat_Room SHALL render Owner_Announcement messages with the app logo (`assets/images/logo.png`) as the avatar, the "Meal Manager" display name, and a light-green highlighted background card that is visually distinct from all other message types.
3. IF a user who is not a superAdmin or systemAdmin attempts to write a Message with `isOwnerAnnouncement: true`, THEN THE Chat_Service SHALL reject the write and return an error.
4. THE Chat_Room SHALL not display a reply or pin option for Owner_Announcement messages for regular members.

---

### Requirement 11: Access Control

**User Story:** As a mess system, I want to enforce access rules on the chat room, so that only authorized users can perform specific actions.

#### Acceptance Criteria

1. THE Chat_Service SHALL verify that the current user's UID exists in `messes/{messId}/members` with `isActive: true` before allowing any message send operation.
2. THE Chat_Service SHALL verify that the current user has `senderRole: 'manager'` before allowing pin or unpin operations.
3. IF a removed or inactive member attempts to send a message, THEN THE Chat_Service SHALL reject the write and display an error message to the user.
4. THE Chat_Room SHALL display past messages to all current active members regardless of when they joined the mess.
5. THE Chat_Room SHALL not provide any private or direct messaging capability; all messages are visible to all active members of the mess.

---

### Requirement 12: Message Data Model

**User Story:** As a developer, I want a well-defined Firestore data model for chat messages, so that the data is consistent and serializable across the app.

#### Acceptance Criteria

1. THE Chat_Service SHALL serialize and deserialize Message documents using a `ChatMessageModel` class with fields: `id` (String), `senderId` (String), `senderName` (String), `senderRole` (String), `text` (String), `timestamp` (Timestamp), `replyTo` (`ReplyReference?`), `seenBy` (List\<String\>), `isPinned` (bool), `isOwnerAnnouncement` (bool).
2. THE Chat_Service SHALL serialize and deserialize `ReplyReference` objects with fields: `msgId` (String), `senderName` (String), `text` (String).
3. FOR ALL valid `ChatMessageModel` instances, `ChatMessageModel.fromFirestore(model.toFirestore())` SHALL produce an object with identical field values (round-trip property).
4. FOR ALL valid `ReplyReference` instances, `ReplyReference.fromMap(ref.toMap())` SHALL produce an object with identical field values (round-trip property).
