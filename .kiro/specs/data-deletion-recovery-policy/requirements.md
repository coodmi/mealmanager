# Requirements Document

## Introduction

This feature implements a comprehensive Data Deletion & Recovery Policy for the Flutter + Firebase mess management app. It covers automated scheduled cleanup of ephemeral data (notifications, chat, join requests) after 40 days, automated deletion of mess operational data (meals, expenses, transactions) after 6 months, inactivity-based mess deletion after 6 months of no activity, soft-delete with a 30-day recycle bin for manager-deleted messes, and an Admin Panel Recycle Bin UI for mess recovery. The policy is enforced via Firebase Cloud Functions (scheduled) and surfaced to admins through a dedicated Recycle Bin page.

## Glossary

- **Scheduler**: The Firebase Cloud Functions scheduled job system (using `onSchedule` from `firebase-functions/v2/scheduler`)
- **Mess**: A mess document stored in the `messes/{messId}` Firestore collection
- **Mess_Data**: Operational subcollection data under a mess: `meals`, `expenses`, `transactions`, `withdrawals`, `monthSummaries`, `members`, `joinRequests`
- **Ephemeral_Data**: Short-lived data subject to 40-day deletion: `notifications` (top/home), `joinRequests`, and `chatMessages`
- **Soft_Delete**: Marking a mess document with `deletedAt` and `isDeleted: true` instead of immediate permanent removal
- **Recycle_Bin**: The collection `deleted_messes` holding soft-deleted mess documents pending permanent deletion
- **Inactivity**: A mess where no meal, expense, transaction, or withdrawal document has been created or updated within the last 6 months, determined by the `lastActivityAt` field on the mess document
- **Admin_Panel**: The Flutter web admin dashboard used by system administrators
- **Recovery_Window**: The 30-day period after soft-deletion during which a mess can be restored
- **Manager**: The user with `role == 'manager'` who owns and manages a mess
- **System_Admin**: A user with `role` in `['superAdmin', 'systemAdmin', 'supportAdmin', 'contentAdmin']`

---

## Requirements

### Requirement 1: Mess Activity Tracking

**User Story:** As a system, I want to track the last activity timestamp on each mess, so that inactivity-based deletion can be accurately triggered.

#### Acceptance Criteria

1. WHEN a meal, expense, transaction, or withdrawal document is created or updated under a mess, THE Mess SHALL have its `lastActivityAt` field updated to the current server timestamp.
2. WHEN a mess is first created, THE Mess SHALL have its `lastActivityAt` field set to the creation server timestamp.
3. THE Mess SHALL store `lastActivityAt` as a Firestore `Timestamp` field at the root of the mess document.
4. IF a mess document does not have a `lastActivityAt` field, THEN THE Scheduler SHALL treat the mess `createdAt` field as the `lastActivityAt` value for inactivity calculations.

---

### Requirement 2: Soft-Delete on Manager-Initiated Mess Deletion

**User Story:** As a manager, I want my mess deletion to be reversible within 30 days, so that accidental or regretted deletions can be recovered by an admin.

#### Acceptance Criteria

1. WHEN a manager triggers mess deletion, THE System SHALL perform a soft-delete by writing the mess document to the `deleted_messes/{messId}` collection with all original fields preserved, plus `deletedAt` set to the server timestamp, `deletedBy` set to the manager's UID, and `isDeleted: true`.
2. WHEN a soft-delete is performed, THE System SHALL remove the mess document from the `messes/{messId}` collection.
3. WHEN a soft-delete is performed, THE System SHALL update all member user documents by clearing their `messId` field and resetting their `role` to `'member'`.
4. WHEN a soft-delete is performed, THE System SHALL display a confirmation message to the manager informing them that the mess can be recovered within 30 days by contacting support, and that recovery is performed by an admin via Admin Panel > Mess > Recycle Bin.
5. WHEN a user contacts support about a deleted mess, THE System SHALL allow recovery only if the request is made within 30 days of deletion; after 30 days, data recovery is not possible.
5. THE System SHALL NOT permanently delete mess subcollection data (meals, expenses, transactions, withdrawals, monthSummaries, members, joinRequests) at the time of soft-delete; subcollection data SHALL remain under `messes/{messId}` subcollections until the permanent deletion job runs.

---

### Requirement 3: 30-Day Recycle Bin Expiry and Permanent Deletion

**User Story:** As a system, I want soft-deleted messes to be permanently removed after 30 days, so that Firestore storage is reclaimed for unrecovered deletions.

#### Acceptance Criteria

1. THE Scheduler SHALL run a permanent deletion job once every 24 hours.
2. WHEN the permanent deletion job runs, THE Scheduler SHALL query all documents in `deleted_messes` where `deletedAt` is older than 30 days.
3. WHEN a `deleted_messes` document is older than 30 days, THE Scheduler SHALL permanently delete all subcollection documents under `messes/{messId}` (meals, expenses, transactions, withdrawals, monthSummaries, members, joinRequests) in batches of no more than 500 operations per Firestore batch.
4. WHEN all subcollection documents are deleted, THE Scheduler SHALL delete the root `messes/{messId}` document and the corresponding `deleted_messes/{messId}` document.
5. IF the permanent deletion job encounters an error for a specific mess, THEN THE Scheduler SHALL log the error and continue processing remaining messes without aborting the entire job.

---

### Requirement 4: 40-Day Ephemeral Data Cleanup

**User Story:** As a system, I want notifications, join requests, and chat messages older than 40 days to be automatically deleted, so that Firestore storage is not consumed by stale ephemeral data.

#### Acceptance Criteria

1. THE Scheduler SHALL run a 40-day ephemeral cleanup job once every 24 hours.
2. WHEN the 40-day cleanup job runs, THE Scheduler SHALL delete all documents in the `adminNotifications` collection where `sentAt` is older than 40 days.
3. WHEN the 40-day cleanup job runs, THE Scheduler SHALL delete all documents in each mess's `joinRequests` subcollection where `createdAt` is older than 40 days.
4. WHEN the 40-day cleanup job runs, THE Scheduler SHALL delete all documents in each mess's `chatMessages` subcollection where `sentAt` is older than 40 days.
5. WHEN the 40-day cleanup job runs, THE Scheduler SHALL delete all documents in the top-level `notifications` collection (home/top notifications) where `createdAt` is older than 40 days.
6. THE Scheduler SHALL NOT delete transaction, meal, expense, withdrawal, or monthSummary documents during the 40-day cleanup job.
7. IF the 40-day cleanup job encounters an error for a specific collection or mess, THEN THE Scheduler SHALL log the error and continue processing remaining items.

---

### Requirement 5: 6-Month Mess Operational Data Cleanup

**User Story:** As a system, I want mess operational data older than 6 months to be automatically deleted, so that Firestore storage costs are controlled over time.

#### Acceptance Criteria

1. THE Scheduler SHALL run a 6-month mess data cleanup job once every 24 hours.
2. WHEN the 6-month cleanup job runs, THE Scheduler SHALL delete all documents in each active mess's `meals` subcollection where `date` (or `createdAt`) is older than 6 months (180 days).
3. WHEN the 6-month cleanup job runs, THE Scheduler SHALL delete all documents in each active mess's `expenses` subcollection where `date` (or `createdAt`) is older than 6 months.
4. WHEN the 6-month cleanup job runs, THE Scheduler SHALL delete all documents in each active mess's `transactions` subcollection where `date` (or `createdAt`) is older than 6 months.
5. WHEN the 6-month cleanup job runs, THE Scheduler SHALL delete all documents in each active mess's `withdrawals` subcollection where `date` (or `createdAt`) is older than 6 months.
6. THE Scheduler SHALL NOT delete `monthSummaries` or `members` documents during the 6-month operational data cleanup.
7. IF the 6-month cleanup job encounters an error for a specific subcollection or mess, THEN THE Scheduler SHALL log the error and continue processing remaining items.

---

### Requirement 6: 6-Month Inactivity-Based Mess Deletion

**User Story:** As a system, I want inactive messes to be automatically soft-deleted after 6 months of inactivity, so that abandoned messes do not consume Firestore resources indefinitely.

#### Acceptance Criteria

1. THE Scheduler SHALL run an inactivity detection job once every 24 hours.
2. WHEN the inactivity detection job runs, THE Scheduler SHALL query all documents in the `messes` collection where `lastActivityAt` is older than 6 months (180 days).
3. WHEN an inactive mess is detected, THE Scheduler SHALL perform a soft-delete by writing the mess to `deleted_messes/{messId}` with `deletedAt` set to the server timestamp, `deletedBy` set to `'system'`, `isDeleted: true`, and `deletionReason` set to `'inactivity'`.
4. WHEN an inactivity soft-delete is performed, THE Scheduler SHALL update all member user documents by clearing their `messId` field and resetting their `role` to `'member'`.
5. IF the inactivity detection job encounters an error for a specific mess, THEN THE Scheduler SHALL log the error and continue processing remaining messes.

---

### Requirement 7: Admin Panel Recycle Bin UI

**User Story:** As a system admin, I want a Recycle Bin page in the Admin Panel, so that I can view and restore soft-deleted messes within the 30-day recovery window.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a Recycle Bin page accessible from the Admin Panel navigation under the Mess section.
2. WHEN the Recycle Bin page loads, THE Admin_Panel SHALL display a list of all documents in the `deleted_messes` collection, showing mess name, mess ID, deletion date, deleted by (manager UID or 'system'), deletion reason, and the number of days remaining in the recovery window.
3. WHILE a deleted mess has a `deletedAt` timestamp within the last 30 days, THE Admin_Panel SHALL display a "Restore" action button for that mess.
4. WHEN a System_Admin clicks "Restore" for a mess within the recovery window, THE Admin_Panel SHALL write the mess document back to `messes/{messId}` with the `isDeleted` field removed and `restoredAt` set to the server timestamp.
5. WHEN a mess is restored, THE Admin_Panel SHALL delete the corresponding document from `deleted_messes/{messId}`.
6. WHEN a mess is restored, THE Admin_Panel SHALL display a success confirmation to the admin.
7. IF a deleted mess has a `deletedAt` timestamp older than 30 days, THEN THE Admin_Panel SHALL display the mess as expired with no Restore button, indicating permanent deletion is pending.
8. THE Admin_Panel SHALL display the Recycle Bin list in descending order of `deletedAt` (most recently deleted first).

---

### Requirement 8: Firestore Security Rules for Deletion Collections

**User Story:** As a system, I want Firestore security rules to protect the deletion-related collections, so that only authorized parties can read or write recycle bin and deletion metadata.

#### Acceptance Criteria

1. THE System SHALL restrict read and write access to the `deleted_messes` collection to System_Admin users only.
2. THE System SHALL allow Cloud Functions (server-side) to read and write `deleted_messes` documents using the Firebase Admin SDK, bypassing client-side security rules.
3. THE System SHALL deny all client-side write access to the `deleted_messes` collection for non-admin users.
4. IF a non-admin authenticated user attempts to read or write to `deleted_messes`, THEN THE System SHALL reject the request with a permission-denied error.

---

### Requirement 9: Deletion Audit Logging

**User Story:** As a system admin, I want all automated and manual deletion events to be logged, so that I can audit what data was deleted and when.

#### Acceptance Criteria

1. WHEN the Scheduler performs any automated deletion (ephemeral, 6-month, inactivity, or permanent recycle bin expiry), THE Scheduler SHALL write a log entry to the `systemLogs` collection with fields: `type` (e.g. `'auto_deletion'`), `target` (collection/messId), `count` (number of documents deleted), `deletedAt` (server timestamp), and `triggeredBy` set to `'scheduler'`.
2. WHEN a manager performs a soft-delete, THE System SHALL write a log entry to `systemLogs` with `type: 'soft_delete'`, `messId`, `deletedBy` (manager UID), and `deletedAt`.
3. WHEN a System_Admin restores a mess from the Recycle Bin, THE System SHALL write a log entry to `systemLogs` with `type: 'mess_restored'`, `messId`, `restoredBy` (admin UID), and `restoredAt`.
