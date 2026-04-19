# Implementation Plan: Data Deletion Policy

## Overview

Flutter + Firestore-ভিত্তিক Mess Management App-এ automated data retention policy implement করা হবে। `DeletionPolicyService` এবং `DeletionScheduler` তৈরি করে app launch-এ integrate করা হবে।

## Tasks

- [x] 1. Core service files ও interfaces তৈরি করা
  - `lib/core/services/deletion_scheduler.dart` ফাইল তৈরি করো
  - `lib/core/services/deletion_policy_service.dart` ফাইল তৈরি করো
  - `DeletionSummary` data class define করো (messId, deletedMonths, totalDocumentsDeleted, errors, ranAt)
  - _Requirements: 1.1, 2.1, 3.1_

- [x] 2. `DeletionScheduler` implement করা
  - [x] 2.1 SharedPreferences throttle logic implement করো
    - `_prefKey = 'deletion_last_run_date'` দিয়ে last run date read/write করো
    - `_getLastRunDate()` এবং `_saveRunDate()` private methods লেখো
    - `runIfNeeded()` — আজকে আগে run হয়নি হলে `DeletionPolicyService.runAll()` call করো, নইলে skip করো
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ]* 2.2 Property test লেখো — Property 2: Deletion Throttle (once per day)
    - **Property 2: Deletion Throttle — Once Per Day**
    - **Validates: Requirements 2.2, 2.3**
    - একই calendar day-এ একাধিক `runIfNeeded()` call-এ শুধু প্রথমটি deletion trigger করে verify করো

- [x] 3. `_getExpiredMonthKeys` ও `_get40DayCutoff` implement করা
  - [x] 3.1 `_getExpiredMonthKeys(String runningMonthKey)` implement করো
    - `YYYY-MM` format parse করো
    - running month থেকে 6 calendar month আগের cutoff বের করো
    - cutoff-এর চেয়ে পুরনো সব monthKey list return করো (running month ও 6 recent months বাদ দিয়ে)
    - _Requirements: 1.1, 1.2, 1.3, 7.1, 7.2_

  - [ ]* 3.2 Property test লেখো — Property 1: 6-Month Cutoff Correctness
    - **Property 1: 6-Month Cutoff Correctness**
    - **Validates: Requirements 1.1, 1.2, 1.3, 7.1, 7.2**
    - যেকোনো valid `YYYY-MM` input-এ running month ও 6 recent months কখনো expired list-এ নেই verify করো

  - [x] 3.3 `_get40DayCutoff()` implement করো
    - `DateTime.now().subtract(const Duration(days: 40))` return করো
    - _Requirements: 8.1_

- [x] 4. `_batchDelete` helper implement করা
  - [x] 4.1 `_batchDelete(List<DocumentReference> refs)` implement করো
    - refs-কে 500-এর chunk-এ ভাগ করো
    - প্রতিটি chunk-এর জন্য Firestore `WriteBatch` তৈরি করে commit করো
    - failed batch log করো, পরের batch-এ continue করো
    - deleted count return করো
    - _Requirements: 7.4, 8.8_

  - [ ]* 4.2 Property test লেখো — Property 5: Batch Size Invariant
    - **Property 5: Batch Size Invariant**
    - **Validates: Requirements 7.4, 8.8**
    - যেকোনো N document refs-এ কোনো single batch-এ 500-এর বেশি operations নেই verify করো

  - [ ]* 4.3 Property test লেখো — Property 4: Error Resilience
    - **Property 4: Error Resilience**
    - **Validates: Requirements 3.6, 8.7**
    - কিছু Firestore delete fail করলেও service unhandled exception throw না করে continue করে verify করো

- [x] 5. Checkpoint — এখন পর্যন্ত সব tests pass করো
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. `run6MonthPolicy` implement করা
  - [x] 6.1 `run6MonthPolicy(String messId)` implement করো
    - `ActiveMonthService.getRunningMonthKey(messId)` দিয়ে running month নাও
    - `_getExpiredMonthKeys()` দিয়ে expired months বের করো
    - প্রতিটি expired month-এর জন্য dry-run count log করো (Requirement 7.3)
    - Top-level `meals` collection query করো: `messId == messId && date` falls in expired month
    - Top-level `expenses`, `transactions`, `withdrawals` query করো: `messId == messId && monthKey == expiredMonth`
    - `messes/{messId}/monthSummaries/{expiredMonth}` document ref নাও
    - সব refs একসাথে `_batchDelete()` দিয়ে delete করো
    - `DeletionSummary` return করো
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 7.3_

  - [ ]* 6.2 Property test লেখো — Property 3: Deletion Completeness for Expired Months
    - **Property 3: Deletion Completeness for Expired Months**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
    - যেকোনো mess ও expired month-এ deletion job-এর পর ওই month-এর কোনো document remain করে না verify করো

- [x] 7. `run40DayPolicy` implement করা
  - [x] 7.1 `run40DayPolicy({required String messId, required String userId})` implement করো
    - `_get40DayCutoff()` দিয়ে cutoff date নাও
    - `users/{userId}/notifications` query করো: `createdAt < cutoff` (সব NotificationTypes)
    - `messes/{messId}/chats` query করো: `createdAt < cutoff`
    - `transactions`, `meals`, `withdrawals` collections এই policy-তে include করা যাবে না
    - সব refs `_batchDelete()` দিয়ে delete করো
    - `DeletionSummary` return করো
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 9.1, 9.2, 9.5_

  - [ ]* 7.2 Property test লেখো — Property 6: 40-Day Cutoff Correctness
    - **Property 6: 40-Day Cutoff Correctness**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**
    - যেকোনো notification/chat document timestamp-এ ঠিক 40 দিনের বেশি পুরনো হলেই delete হয় verify করো

  - [ ]* 7.3 Property test লেখো — Property 7: Policy Scope Isolation
    - **Property 7: Policy Scope Isolation**
    - **Validates: Requirements 9.1, 9.2, 9.5**
    - `transactions`, `meals`, `withdrawals` collections কখনো 40-day policy code path-এ include হয় না verify করো

- [x] 8. `runAll` ও Manager notification implement করা
  - [x] 8.1 `runAll()` implement করো
    - Current user-এর joined messIds নাও
    - প্রতিটি messId-এর জন্য `run6MonthPolicy()` ও `run40DayPolicy()` call করো
    - সব `DeletionSummary` aggregate করো
    - _Requirements: 2.1, 6.1_

  - [x] 8.2 Manager-only deletion notification implement করো
    - Current user-এর role check করো
    - Role == `manager` হলে deleted months ও document count সহ in-app notification দেখাও
    - Regular member-এর জন্য notification skip করো
    - _Requirements: 6.2, 6.3_

  - [ ]* 8.3 Property test লেখো — Property 8: Manager-Only Deletion Notification
    - **Property 8: Manager-Only Deletion Notification**
    - **Validates: Requirements 6.3**
    - যেকোনো user role-এ শুধু `manager` role-এ notification দেখায় verify করো

- [x] 9. App launch integration
  - [x] 9.1 `DashboardPage` (বা authenticated entry point)-এর `initState`-এ `DeletionScheduler.runIfNeeded()` call করো
    - Fire-and-forget হিসেবে call করো (await করা হবে না)
    - UI block হবে না নিশ্চিত করো
    - _Requirements: 2.1, 5.2_

- [x] 10. Checkpoint — সব tests pass করো এবং integration verify করো
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Policy (b): `lastActivityAt` tracking implement করা
  - [ ] 11.1 Mess creation-এ `lastActivityAt` set করো
    - Mess তৈরির সময় `messes/{messId}` document-এ `lastActivityAt: FieldValue.serverTimestamp()` যোগ করো
    - _Requirements: 10.1, 10.2, 10.3_

  - [ ] 11.2 Activity write-এ `lastActivityAt` update করো
    - `DeletionPolicyService`-এ `updateLastActivity(String messId)` static method যোগ করো
    - `messes/{messId}` document-এ `lastActivityAt: FieldValue.serverTimestamp()` update করো
    - Meal, expense, transaction, withdrawal add/update করার সময় এই method call করো
    - _Requirements: 10.1, 10.3_

- [ ] 12. Policy (b): `runInactivityPolicy` implement করা
  - [ ] 12.1 `runInactivityPolicy()` method implement করো
    - `DeletionPolicyService`-এ `runInactivityPolicy()` static method যোগ করো
    - `messes` collection query করো: `lastActivityAt < 180 days ago` (fallback: `createdAt`)
    - প্রতিটি inactive mess-এর জন্য soft-delete: `deleted_messes/{messId}` তে write করো
    - Soft-delete fields: সব original fields + `deletedAt`, `deletedBy: 'system'`, `isDeleted: true`, `deletionReason: 'inactivity'`
    - `messes/{messId}` root doc delete করো
    - সব member user documents update করো: `messId: ''`, `role: 'member'`
    - Error হলে log করে continue করো
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

  - [ ] 12.2 `runAll()` এ `runInactivityPolicy()` যোগ করো
    - `DeletionPolicyService.runAll()` method-এ `runInactivityPolicy()` call যোগ করো
    - _Requirements: 11.1_

- [ ] 13. Final Checkpoint — সব tests pass করো
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- `*` চিহ্নিত sub-tasks optional — MVP-র জন্য skip করা যাবে
- প্রতিটি task specific requirements reference করে traceability নিশ্চিত করে
- Property tests-এ [glados](https://pub.dev/packages/glados) library ব্যবহার করো
- `_batchDelete` সব deletion-এর shared helper — আগে implement করো
- Fire-and-forget pattern নিশ্চিত করো যাতে app launch slow না হয়
