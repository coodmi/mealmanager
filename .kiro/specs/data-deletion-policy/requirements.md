# Requirements Document

## Introduction

এই ফিচারটি Running Mess-এর পুরনো data automatically delete করার policy implement করে।
Firestore storage cost কমাতে তিনটি আলাদা retention period প্রযোজ্য:

- **৬ মাসের policy (a):** প্রতিটি mess-এর core operational data — meals, expenses, transactions, withdrawals, এবং monthSummaries — সর্বোচ্চ ৬ মাস পর্যন্ত রাখা হবে। এর মধ্যে Transactions page, Memberwise personal Meal history, এবং Memberwise personal Transaction history-ও অন্তর্ভুক্ত।
- **৬ মাসের policy (b):** Inactive full mess — যে mess-এ ৬ মাস ধরে কোনো activity নেই — সেটি automatically delete হবে।
- **৪০ দিনের policy (c):** Notifications (Mess requests, My requests, Home top notifications) এবং Chat messages — ৪০ দিন পর automatically delete হবে।

উভয় ক্ষেত্রেই expired data Firestore থেকে automatically delete হবে এবং Flutter frontend-এও আর দেখাবে না।

## Glossary

- **DeletionPolicy_Service**: Flutter app-এর সেই service যা data deletion policy enforce করে
- **Scheduler**: App startup বা periodic trigger-এ deletion job চালানোর mechanism
- **MessId**: প্রতিটি mess-এর unique identifier (যেমন: `M00123`)
- **MonthKey**: `YYYY-MM` format-এ month identifier (যেমন: `2025-01`)
- **RetentionPeriod**: Data রাখার সর্বোচ্চ সময়সীমা — ৬ calendar month
- **ExpiredMonth**: যে monthKey-এর data retention period পার করেছে
- **AffectedCollections**: Firestore-এ যে subcollections delete হবে — `meals`, `expenses`, `transactions`, `withdrawals`, `monthSummaries`
- **RunningMonth**: বর্তমানে active/open month যেটি এখনো close হয়নি
- **Manager**: Mess-এর admin user যিনি mess পরিচালনা করেন
- **NotificationRetentionPeriod**: Notifications এবং Chat messages রাখার সর্বোচ্চ সময়সীমা — ৪০ calendar days
- **ChatMessage**: Mess-এর chat section-এ user-দের পাঠানো message document; Firestore-এ `messes/{messId}/chats` বা `users/{uid}/chats` collection-এ সংরক্ষিত
- **MessNotification**: App-এ user-দের কাছে পাঠানো notification document; Firestore-এ `users/{uid}/notifications` বা `messes/{messId}/notifications` collection-এ সংরক্ষিত
- **NotificationTypes**: MessNotification-এর তিনটি ধরন — Mess requests (অন্য mess থেকে আসা request), My requests (user নিজে পাঠানো request-এর status), Home top notifications (home screen-এর top-এ দেখানো general notifications)
- **InactiveMess**: যে mess-এ ৬ মাস (180 দিন) ধরে কোনো meal, expense, transaction বা withdrawal activity নেই
- **LastActivityAt**: Mess document-এ `lastActivityAt` Firestore Timestamp field — সর্বশেষ activity-র সময়
- **InactivityDeletionPolicy**: Policy (b) — Inactive mess ৬ মাস পর automatically soft-delete হবে

---

## Requirements

### Requirement 1: Data Retention Period নির্ধারণ

**User Story:** As a mess manager, I want old mess data to be automatically removed after 6 months, so that Firestore storage costs remain manageable.

#### Acceptance Criteria

1. THE DeletionPolicy_Service SHALL define the retention period as 6 calendar months prior to the current RunningMonth.
2. WHEN calculating expired months, THE DeletionPolicy_Service SHALL treat any MonthKey older than 6 months before the current RunningMonth as an ExpiredMonth.
3. THE DeletionPolicy_Service SHALL NOT delete data from the current RunningMonth or any of the 6 most recent closed months.

---

### Requirement 2: Automatic Deletion Trigger

**User Story:** As a mess manager, I want data deletion to happen automatically without manual intervention, so that I don't have to manage storage manually.

#### Acceptance Criteria

1. WHEN the Flutter app is launched, THE Scheduler SHALL invoke the DeletionPolicy_Service to check and delete expired data for all messes the current user belongs to.
2. THE DeletionPolicy_Service SHALL run the deletion check at most once per calendar day per device to avoid redundant Firestore operations.
3. IF the deletion check has already run today, THEN THE Scheduler SHALL skip the deletion job until the next calendar day.

---

### Requirement 3: Firestore Data Deletion

**User Story:** As a mess manager, I want expired data to be permanently removed from Firestore, so that storage space is freed up.

#### Acceptance Criteria

1. WHEN an ExpiredMonth is identified for a mess, THE DeletionPolicy_Service SHALL delete all documents in `messes/{messId}/meals` where the document's `date` field falls within that ExpiredMonth.
2. WHEN an ExpiredMonth is identified for a mess, THE DeletionPolicy_Service SHALL delete all documents in `messes/{messId}/expenses` where the document's `monthKey` field equals that ExpiredMonth.
3. WHEN an ExpiredMonth is identified for a mess, THE DeletionPolicy_Service SHALL delete all documents in `messes/{messId}/transactions` where the document's `monthKey` field equals that ExpiredMonth.
4. WHEN an ExpiredMonth is identified for a mess, THE DeletionPolicy_Service SHALL delete all documents in `messes/{messId}/withdrawals` where the document's `monthKey` field equals that ExpiredMonth.
5. WHEN an ExpiredMonth is identified for a mess, THE DeletionPolicy_Service SHALL delete the document `messes/{messId}/monthSummaries/{expiredMonthKey}`.
6. IF a Firestore delete operation fails, THEN THE DeletionPolicy_Service SHALL log the error and continue deleting remaining documents without interrupting the overall deletion process.

---

### Requirement 4: Collection Path Compatibility

**User Story:** As a developer, I want the deletion service to handle both top-level and subcollection data paths, so that all data structures are covered correctly.

#### Acceptance Criteria

1. THE DeletionPolicy_Service SHALL support deletion from top-level `meals` collection where documents contain a `messId` field matching the target mess.
2. THE DeletionPolicy_Service SHALL support deletion from top-level `expenses` collection where documents contain a `messId` field matching the target mess.
3. THE DeletionPolicy_Service SHALL support deletion from top-level `transactions` collection where documents contain a `messId` field matching the target mess.
4. THE DeletionPolicy_Service SHALL support deletion from top-level `withdrawals` collection where documents contain a `messId` field matching the target mess.
5. WHEN querying top-level collections, THE DeletionPolicy_Service SHALL filter by both `messId` and the date/monthKey field to identify expired documents.

---

### Requirement 5: Frontend Data Visibility

**User Story:** As a mess member, I want the app to not display deleted historical data, so that the UI remains consistent with what's stored in Firestore.

#### Acceptance Criteria

1. WHEN data for an ExpiredMonth has been deleted from Firestore, THE Flutter app SHALL not display that month's data in any report, history, or summary screen.
2. WHILE the DeletionPolicy_Service is running a deletion job, THE Flutter app SHALL continue to function normally without freezing or showing errors to the user.
3. IF a user navigates to a screen that previously showed expired data, THEN THE Flutter app SHALL display an empty state indicating no data is available for that period.

---

### Requirement 6: Manager Notification

**User Story:** As a mess manager, I want to be informed when old data has been deleted, so that I'm aware of what data is no longer available.

#### Acceptance Criteria

1. WHEN the DeletionPolicy_Service successfully deletes data for one or more ExpiredMonths, THE DeletionPolicy_Service SHALL log a summary of deleted months and document counts.
2. WHERE in-app notification is enabled, THE DeletionPolicy_Service SHALL display a one-time notification to the Manager indicating which months' data was deleted.
3. THE DeletionPolicy_Service SHALL NOT show deletion notifications to regular members — only to the Manager.

---

### Requirement 7: Deletion Safety Guard

**User Story:** As a mess manager, I want the system to never accidentally delete recent or current data, so that active mess operations are not disrupted.

#### Acceptance Criteria

1. THE DeletionPolicy_Service SHALL verify that a MonthKey is strictly older than 6 months before marking it as an ExpiredMonth.
2. IF the calculated ExpiredMonth is equal to or newer than the 6-month cutoff, THEN THE DeletionPolicy_Service SHALL abort deletion for that month and log a warning.
3. THE DeletionPolicy_Service SHALL perform a dry-run count of documents to be deleted before executing batch deletes, and SHALL log the count.
4. WHEN the total document count to be deleted in a single run exceeds 500, THE DeletionPolicy_Service SHALL process deletions in batches of at most 500 documents per Firestore batch write.

---

### Requirement 8: Notification ও Chat Message Deletion (40-day policy)

**User Story:** As a mess member, I want old notifications and chat messages to be automatically removed after 40 days, so that irrelevant or outdated communication data does not accumulate in storage.

#### Acceptance Criteria

1. THE DeletionPolicy_Service SHALL define the NotificationRetentionPeriod as 40 calendar days prior to the current date.
2. WHEN the deletion job runs, THE DeletionPolicy_Service SHALL delete all MessNotification documents where the `createdAt` or `timestamp` field is older than 40 days from the current date.
3. WHEN the deletion job runs, THE DeletionPolicy_Service SHALL delete all ChatMessage documents where the `createdAt` or `timestamp` field is older than 40 days from the current date.
4. THE DeletionPolicy_Service SHALL apply the 40-day deletion rule to all NotificationTypes — Mess requests, My requests, and Home top notifications — without exception.
5. WHEN deleting MessNotification documents, THE DeletionPolicy_Service SHALL query `users/{uid}/notifications` or `messes/{messId}/notifications` collections filtered by the age field.
6. WHEN deleting ChatMessage documents, THE DeletionPolicy_Service SHALL query `messes/{messId}/chats` or `users/{uid}/chats` collections filtered by the age field.
7. IF a Firestore delete operation for a MessNotification or ChatMessage fails, THEN THE DeletionPolicy_Service SHALL log the error and continue deleting remaining documents without interrupting the overall deletion process.
8. WHEN the total MessNotification or ChatMessage document count to be deleted in a single run exceeds 500, THE DeletionPolicy_Service SHALL process deletions in batches of at most 500 documents per Firestore batch write.

---

### Requirement 9: Transaction ও Personal History Exception (40-day rule থেকে exempt)

**User Story:** As a mess member, I want my transaction records and personal meal/transaction history to remain accessible beyond 40 days, so that I can review my financial and meal history for the full 6-month retention period.

#### Acceptance Criteria

1. THE DeletionPolicy_Service SHALL NOT apply the 40-day NotificationRetentionPeriod to any document in the Transactions page, Memberwise personal Meal history, or Memberwise personal Transaction history.
2. WHILE the 40-day deletion job is running, THE DeletionPolicy_Service SHALL explicitly exclude `transactions`, `meals` (personal history), and related summary documents from the NotificationRetentionPeriod deletion scope.
3. THE DeletionPolicy_Service SHALL apply the 6-month RetentionPeriod (policy a, b) to Transactions page data, Memberwise personal Meal history, and Memberwise personal Transaction history — consistent with Requirement 1 and Requirement 3.
4. IF a document belongs to both a notification-related collection and a transaction/history collection, THEN THE DeletionPolicy_Service SHALL treat it under the 6-month RetentionPeriod, not the 40-day NotificationRetentionPeriod.
5. THE DeletionPolicy_Service SHALL maintain separate deletion scopes for the 40-day policy (notifications, chat messages) and the 6-month policy (meals, expenses, transactions, withdrawals, monthSummaries) to prevent accidental cross-policy deletion.

---

### Requirement 10: Inactive Mess Activity Tracking (Policy b)

**User Story:** As a system, I want to track the last activity timestamp on each mess, so that inactivity-based deletion can be accurately triggered.

#### Acceptance Criteria

1. WHEN a meal, expense, transaction, or withdrawal document is created or updated under a mess, THE mess document SHALL have its `lastActivityAt` field updated to the current server timestamp.
2. WHEN a mess is first created, THE mess document SHALL have its `lastActivityAt` field set to the creation server timestamp.
3. THE mess document SHALL store `lastActivityAt` as a Firestore `Timestamp` field at the root of the mess document (`messes/{messId}`).
4. IF a mess document does not have a `lastActivityAt` field, THEN THE DeletionPolicy_Service SHALL treat the mess `createdAt` field as the `lastActivityAt` value for inactivity calculations.

---

### Requirement 11: Inactive Mess Auto-Delete (Policy b)

**User Story:** As a system, I want inactive messes to be automatically deleted after 6 months of inactivity, so that abandoned messes do not consume Firestore resources indefinitely.

#### Acceptance Criteria

1. WHEN the deletion job runs, THE DeletionPolicy_Service SHALL query all documents in the `messes` collection where `lastActivityAt` is older than 180 days (6 months) from the current date.
2. WHEN an InactiveMess is detected, THE DeletionPolicy_Service SHALL perform a soft-delete by writing the mess document to `deleted_messes/{messId}` with all original fields preserved, plus `deletedAt` set to the current timestamp, `deletedBy` set to `'system'`, `isDeleted: true`, and `deletionReason` set to `'inactivity'`.
3. WHEN an inactivity soft-delete is performed, THE DeletionPolicy_Service SHALL remove the mess document from the `messes/{messId}` collection.
4. WHEN an inactivity soft-delete is performed, THE DeletionPolicy_Service SHALL update all member user documents by clearing their `messId` field and resetting their `role` to `'member'`.
5. THE DeletionPolicy_Service SHALL NOT permanently delete mess subcollection data (meals, expenses, transactions, withdrawals, monthSummaries, members) at the time of inactivity soft-delete; subcollection data SHALL remain until the recovery window expires.
6. IF the inactivity detection job encounters an error for a specific mess, THEN THE DeletionPolicy_Service SHALL log the error and continue processing remaining messes.
7. THE DeletionPolicy_Service SHALL NOT soft-delete a mess if its `lastActivityAt` is within the last 180 days, even if the mess appears otherwise inactive.
