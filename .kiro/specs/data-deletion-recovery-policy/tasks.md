# Implementation Plan: Data Deletion & Recovery Policy

## Overview

Migrate Cloud Functions to TypeScript, implement soft-delete/restore callables, four scheduled cleanup jobs, an activity tracking trigger, Flutter UI changes (updated delete flow + Admin Recycle Bin), and updated Firestore security rules.

## Tasks

- [x] 1. Cloud Functions: TypeScript migration and project setup
  - Add `typescript`, `ts-node`, `@types/node` dev dependencies to `functions/package.json`
  - Add `fast-check` and `@firebase/rules-unit-testing` dev dependencies
  - Add `build` script (`tsc`) and update `main` to `lib/index.js` in `package.json`
  - Create `functions/tsconfig.json` with strict mode targeting ES2020
  - Create `functions/src/` directory structure: `cleanup/`, `callable/`, `triggers/`, `utils/`
  - Create `functions/src/index.ts` that re-exports all functions (initially empty stubs)
  - Migrate existing `functions/index.js` `onUserDeleted` function to `functions/src/index.ts` in TypeScript
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1_

- [ ] 2. Implement utility helpers
  - [x] 2.1 Implement `batchDelete` utility in `functions/src/utils/batchDelete.ts`
    - Accept `db: Firestore` and `snap: QuerySnapshot`; chunk into batches of ≤500; return total deleted count
    - _Requirements: 3.3_

  - [ ]* 2.2 Write property test for `batchDelete` batch size limit
    - **Property 6: Batch size never exceeds 500 operations**
    - **Validates: Requirements 3.3**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 6: Batch size never exceeds 500 operations`
    - Generate arrays of 1–2000 mock doc refs; assert no single batch exceeds 500 ops; run 100 iterations

  - [x] 2.3 Implement `writeSysLog` utility in `functions/src/utils/logging.ts`
    - Accept `db` and a typed log entry object; write to `systemLogs` collection with `FieldValue.serverTimestamp()`
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ]* 2.4 Write property test for `writeSysLog` entry structure
    - **Property 17: systemLogs entry structure for all deletion and restore events**
    - **Validates: Requirements 9.1, 9.2, 9.3**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 17: systemLogs entry structure for all deletion and restore events`
    - Generate random deletion/restore event payloads; assert written doc contains `type`, `triggeredBy`, and at least one of `deletedAt`/`restoredAt`; run 100 iterations

- [ ] 3. Implement activity tracking trigger
  - [x] 3.1 Create `functions/src/triggers/updateLastActivity.ts`
    - Export `updateLastActivity` using `onDocumentWritten('messes/{messId}/{subcol}/{docId}', ...)`
    - Guard: only proceed if `subcol` is in `['meals','expenses','transactions','withdrawals']`
    - Update `messes/{messId}` with `lastActivityAt: FieldValue.serverTimestamp()`
    - Export from `functions/src/index.ts`
    - _Requirements: 1.1, 1.3_

  - [ ]* 3.2 Write property test for activity tracking
    - **Property 1: Activity write updates lastActivityAt**
    - **Validates: Requirements 1.1, 1.3**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 1: Activity write updates lastActivityAt`
    - Generate random subcollection names (tracked and untracked); assert `lastActivityAt` is updated only for tracked subcols; run 100 iterations

- [ ] 4. Implement `softDeleteMess` callable
  - [x] 4.1 Create `functions/src/callable/softDeleteMess.ts`
    - Export `softDeleteMess` using `onCall`; require auth; accept `{ messId: string }`
    - Read `messes/{messId}`; throw `permission-denied` if `managerId !== callerUid`; throw `not-found` if missing
    - Write to `deleted_messes/{messId}` with all original fields + `deletedAt`, `deletedBy`, `isDeleted: true`, `deletionReason: 'manager_request'`
    - Delete `messes/{messId}` root doc
    - Batch-update all `members` docs: set `messId: ''`, `role: 'member'`
    - Call `writeSysLog` with `type: 'soft_delete'`, `messId`, `deletedBy`, `deletedAt`
    - Export from `functions/src/index.ts`
    - _Requirements: 2.1, 2.2, 2.3, 9.2_

  - [ ]* 4.2 Write property test for soft-delete output structure
    - **Property 2: Soft-delete output structure**
    - **Validates: Requirements 2.1, 6.3**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 2: Soft-delete output structure`
    - Generate random mess data; assert `deleted_messes` doc contains all original fields plus `deletedAt`, `deletedBy`, `isDeleted: true`, `deletionReason`; run 100 iterations

  - [ ]* 4.3 Write property test for soft-delete removes from messes
    - **Property 3: Soft-delete removes mess from active collection**
    - **Validates: Requirements 2.2**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 3: Soft-delete removes mess from active collection`
    - Generate random messIds; assert `messes/{messId}` does not exist after soft-delete; run 100 iterations

  - [ ]* 4.4 Write property test for soft-delete clears member documents
    - **Property 4: Soft-delete clears all member documents**
    - **Validates: Requirements 2.3, 6.4**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 4: Soft-delete clears all member documents`
    - Generate random member lists (1–50 members); assert all have `messId: ''` and `role: 'member'` after soft-delete; run 100 iterations

  - [ ]* 4.5 Write property test for subcollections surviving soft-delete
    - **Property 5: Subcollections survive soft-delete**
    - **Validates: Requirements 2.5**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 5: Subcollections survive soft-delete`
    - Generate random subcollection sizes; assert doc counts unchanged after soft-delete; run 100 iterations

- [ ] 5. Implement `restoreMess` callable
  - [x] 5.1 Create `functions/src/callable/restoreMess.ts`
    - Export `restoreMess` using `onCall`; require auth; verify caller has admin role via custom claims
    - Accept `{ messId: string }`; read `deleted_messes/{messId}`; throw `not-found` if missing
    - Throw `failed-precondition` with message "Recovery window expired" if `deletedAt` is older than 30 days
    - Write to `messes/{messId}` with original fields minus `isDeleted`, plus `restoredAt: FieldValue.serverTimestamp()`
    - Delete `deleted_messes/{messId}`
    - Call `writeSysLog` with `type: 'mess_restored'`, `messId`, `restoredBy`, `restoredAt`
    - Export from `functions/src/index.ts`
    - _Requirements: 7.4, 7.5, 9.3_

  - [ ]* 5.2 Write property test for restore round-trip
    - **Property 13: Restore round-trip**
    - **Validates: Requirements 7.4, 7.5**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 13: Restore round-trip`
    - Generate soft-deleted mess docs within 30-day window; assert `messes/{messId}` restored with all original fields + `restoredAt`, no `isDeleted`; assert `deleted_messes/{messId}` absent; run 100 iterations

- [ ] 6. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement `cleanupEphemeralData` scheduled function
  - [x] 7.1 Create `functions/src/cleanup/cleanupEphemeralData.ts`
    - Export `cleanupEphemeralData` using `onSchedule('every 24 hours')`
    - Delete `adminNotifications` docs where `sentAt` < 40 days ago using `batchDelete`
    - Delete top-level `notifications` docs where `createdAt` < 40 days ago using `batchDelete`
    - For each mess in `messes`, delete `joinRequests` docs where `createdAt` < 40 days ago
    - For each mess in `messes`, delete `chatMessages` docs where `sentAt` < 40 days ago
    - Call `writeSysLog` per collection with `type: 'auto_deletion'`, `target`, `count`, `triggeredBy: 'scheduler'`
    - Wrap each collection/mess in try/catch; log error and continue on failure
    - Export from `functions/src/index.ts`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 9.1_

  - [ ]* 7.2 Write property test for ephemeral date filter
    - **Property 8: Ephemeral cleanup date filter selects only docs older than 40 days**
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.5**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 8: Ephemeral cleanup date filter selects only docs older than 40 days`
    - Generate mixed-age doc sets; assert only docs with timestamp > 40 days ago are selected; run 100 iterations

  - [ ]* 7.3 Write property test for ephemeral cleanup excluding protected collections
    - **Property 9: Ephemeral cleanup never touches protected collections**
    - **Validates: Requirements 4.6**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 9: Ephemeral cleanup never touches protected collections`
    - Generate full mess state; assert `meals`, `expenses`, `transactions`, `withdrawals`, `monthSummaries` counts unchanged after job; run 100 iterations

- [ ] 8. Implement `cleanupMessOperationalData` scheduled function
  - [x] 8.1 Create `functions/src/cleanup/cleanupMessOperationalData.ts`
    - Export `cleanupMessOperationalData` using `onSchedule('every 24 hours')`
    - For each mess in `messes`, delete `meals`, `expenses`, `transactions`, `withdrawals` docs where `date` (fallback `createdAt`) < 180 days ago using `batchDelete`
    - Call `writeSysLog` per subcollection with `type: 'auto_deletion'`, `target`, `count`, `triggeredBy: 'scheduler'`
    - Do NOT touch `monthSummaries` or `members`
    - Wrap each subcollection/mess in try/catch; log error and continue on failure
    - Export from `functions/src/index.ts`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 9.1_

  - [ ]* 8.2 Write property test for operational data date filter
    - **Property 10: Operational data cleanup date filter selects only docs older than 180 days**
    - **Validates: Requirements 5.2, 5.3, 5.4, 5.5**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 10: Operational data cleanup date filter selects only docs older than 180 days`
    - Generate mixed-age operational docs; assert only docs with date > 180 days ago are selected; run 100 iterations

  - [ ]* 8.3 Write property test for 6-month cleanup excluding monthSummaries/members
    - **Property 11: 6-month cleanup never touches monthSummaries or members**
    - **Validates: Requirements 5.6**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 11: 6-month cleanup never touches monthSummaries or members`
    - Generate full mess state; assert `monthSummaries` and `members` counts unchanged after job; run 100 iterations

- [ ] 9. Implement `cleanupInactiveMesses` scheduled function
  - [x] 9.1 Create `functions/src/cleanup/cleanupInactiveMesses.ts`
    - Export `cleanupInactiveMesses` using `onSchedule('every 24 hours')`
    - Query `messes` where `lastActivityAt` < 180 days ago (fallback to `createdAt` if field missing)
    - For each inactive mess: write to `deleted_messes/{messId}` with `deletedBy: 'system'`, `isDeleted: true`, `deletionReason: 'inactivity'`, `deletedAt: FieldValue.serverTimestamp()`
    - Batch-update all `members` docs: set `messId: ''`, `role: 'member'`
    - Delete `messes/{messId}` root doc
    - Call `writeSysLog` with `type: 'auto_deletion'`, `target: messId`, `triggeredBy: 'scheduler'`
    - Wrap each mess in try/catch; log error and continue on failure
    - Export from `functions/src/index.ts`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 9.1_

  - [ ]* 9.2 Write property test for inactivity query date filter
    - **Property 12: Inactivity query selects only messes inactive for 180+ days**
    - **Validates: Requirements 6.2**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 12: Inactivity query selects only messes inactive for 180+ days`
    - Generate messes with mixed `lastActivityAt` timestamps; assert only messes with `lastActivityAt` > 180 days ago are selected; run 100 iterations

- [ ] 10. Implement `cleanupExpiredDeletedMesses` scheduled function
  - [x] 10.1 Create `functions/src/cleanup/cleanupExpiredDeletedMesses.ts`
    - Export `cleanupExpiredDeletedMesses` using `onSchedule('every 24 hours')`
    - Query `deleted_messes` where `deletedAt` < 30 days ago
    - For each expired mess: delete all subcollection docs under `messes/{messId}` (meals, expenses, transactions, withdrawals, monthSummaries, members, joinRequests) using `batchDelete`
    - Delete root `messes/{messId}` doc and `deleted_messes/{messId}` doc
    - Call `writeSysLog` with `type: 'auto_deletion'`, `target: messId`, `triggeredBy: 'scheduler'`
    - Wrap each mess in try/catch; log error and continue on failure
    - Export from `functions/src/index.ts`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.1_

  - [ ]* 10.2 Write property test for permanent deletion removing both root documents
    - **Property 7: Permanent deletion removes both root documents**
    - **Validates: Requirements 3.4**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 7: Permanent deletion removes both root documents`
    - Generate expired `deleted_messes` entries; assert neither `messes/{messId}` nor `deleted_messes/{messId}` exist after job; run 100 iterations

- [ ] 11. Checkpoint — Ensure all Cloud Function tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Flutter: Update `MessSettingsPage._doDeleteMess()` to use soft-delete callable
  - [x] 12.1 Add `cloud_functions` import to `mess_settings_page.dart` if not already present
    - _Requirements: 2.1_

  - [x] 12.2 Update `_confirmDeleteMess()` dialog content text
    - Change dialog body to: "Your mess will be moved to the recycle bin. If deleted by the Manager, users may contact support. Deleted mess can be recovered within 30 days only after deletion from Admin Panel > Mess > Recycle Bin. After 30 days, data recovery is not possible."
    - _Requirements: 2.4_

  - [x] 12.3 Replace `_doDeleteMess()` implementation
    - Remove existing direct Firestore batch delete logic
    - Call `FirebaseFunctions.instance.httpsCallable('softDeleteMess').call({'messId': _messId})`
    - On success: show snackbar "Mess deleted. Recoverable within 30 days." then `context.go('/create-join-mess')`
    - On error: show error snackbar with exception message; do not navigate
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 12.4 Write unit tests for updated `_doDeleteMess()` in Dart
    - Mock `FirebaseFunctions` callable; verify it is called with correct `messId`
    - Verify success navigation to `/create-join-mess`
    - Verify error snackbar shown on callable failure without navigation
    - _Requirements: 2.1, 2.4_

- [ ] 13. Flutter: Create `AdminRecycleBinPage` widget
  - [x] 13.1 Create `lib/features/admin/pages/admin_recycle_bin_page.dart`
    - `StreamBuilder` on `FirebaseFirestore.instance.collection('deleted_messes').orderBy('deletedAt', descending: true)`
    - For each doc render: mess name, mess ID, `deletedAt` formatted date, `deletedBy`, `deletionReason`, days remaining in recovery window
    - Compute `daysRemaining = 30 - DateTime.now().difference(deletedAt.toDate()).inDays`
    - If `daysRemaining > 0`: show "Restore" `ElevatedButton` that calls `FirebaseFunctions.instance.httpsCallable('restoreMess').call({'messId': messId})`
    - On restore success: show snackbar "Mess restored successfully"
    - On restore error: show error snackbar; keep list visible
    - If `daysRemaining <= 0`: show "Expired" `Chip` with no Restore button
    - On stream error: show inline error widget with retry button
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8_

  - [ ]* 13.2 Write property test for Recycle Bin restore button visibility
    - **Property 14: Restore button visibility follows 30-day window**
    - **Validates: Requirements 7.3, 7.7**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 14: Restore button visibility follows 30-day window`
    - Use `glados` to generate `DateTime` values across a wide range; assert Restore button shown iff `deletedAt` within last 30 days; assert Expired chip shown otherwise; run 100 iterations

  - [ ]* 13.3 Write property test for Recycle Bin rendering required fields
    - **Property 15: Recycle Bin renders all required fields**
    - **Validates: Requirements 7.2**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 15: Recycle Bin renders all required fields`
    - Generate random `deleted_messes` doc data; assert rendered list item displays name, messId, deletedAt, deletedBy, deletionReason, daysRemaining; run 100 iterations

  - [ ]* 13.4 Write property test for Recycle Bin ordering
    - **Property 16: Recycle Bin list is ordered newest-first**
    - **Validates: Requirements 7.8**
    - Tag: `// Feature: data-deletion-recovery-policy, Property 16: Recycle Bin list is ordered newest-first`
    - Generate randomly ordered `deleted_messes` lists; assert rendered order is descending by `deletedAt`; run 100 iterations

- [ ] 14. Flutter: Add Recycle Bin tab to `AdminShell`
  - [x] 14.1 Add import for `AdminRecycleBinPage` in `admin_shell.dart`
    - _Requirements: 7.1_

  - [x] 14.2 Add `_NavItem(Icons.delete_sweep_rounded, 'Recycle Bin')` to `_navItems` list in `_AdminShellState`
    - _Requirements: 7.1_

  - [x] 14.3 Add `AdminRecycleBinPage()` to `_pages` list at the matching index
    - _Requirements: 7.1_

  - [ ]* 14.4 Write widget test for Recycle Bin tab presence in `AdminShell`
    - Verify `_navItems` contains a 'Recycle Bin' entry
    - Verify tapping the Recycle Bin nav item renders `AdminRecycleBinPage`
    - _Requirements: 7.1_

- [ ] 15. Firestore security rules: add `deleted_messes` and update `systemLogs` rules
  - [x] 15.1 Add `deleted_messes` rule block to `firestore.rules`
    - Allow read and write only if `request.auth != null` and `userRole()` is in `['superAdmin','systemAdmin','supportAdmin','contentAdmin']`
    - _Requirements: 8.1, 8.3, 8.4_

  - [x] 15.2 Update `systemLogs` rule block in `firestore.rules`
    - Allow read only for system admins (already present); set `allow write: if false` to block all client writes
    - _Requirements: 8.2_

- [ ] 16. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Property tests (TypeScript) use `fast-check` with `numRuns: 100`; Dart property tests use `glados`
- Each property test must include the tag comment: `// Feature: data-deletion-recovery-policy, Property N: <text>`
- All Cloud Functions use Firebase Functions v2 (`firebase-functions/v2`)
- `batchDelete` must never exceed 500 ops per Firestore batch (Firestore hard limit)
- The `lastActivityAt` fallback to `createdAt` applies in both the trigger and the inactivity scheduler
