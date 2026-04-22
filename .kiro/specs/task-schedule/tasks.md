# Implementation Plan: Smart Task Schedule

## Overview

Replace the existing list-view `TaskSchedulePage` with a full calendar-based duty management UI. The implementation is split into: service layer (`TaskScheduleService`, `TaskReminderChecker`), extracted stateless widgets (`TaskCalendarGrid`, `TaskDateCell`, `MonthSelectorBar`, `TaskDetailSheet`, `TaskAssignmentSheet`, `MyTasksTab`, `CompletedTasksTab`), and the rebuilt `TaskSchedulePage` that wires everything together with a real-time Firestore stream.

## Tasks

- [ ] 1. Create service layer files and core interfaces
  - Create `lib/features/task/services/task_schedule_service.dart` with class skeleton and method signatures
  - Create `lib/features/task/services/task_reminder_checker.dart` with class skeleton
  - Define the `shouldSendReminder` pure static method signature
  - _Requirements: 8.1, 8.3, 9.1, 11.1, 11.4_

- [ ] 2. Implement `TaskScheduleService` Firestore CRUD
  - [ ] 2.1 Implement `assignTasks` method
    - Use a `WriteBatch` to write N×M `TaskScheduleModel` documents to `messes/{messId}/taskSchedule`
    - In the same batch, write M notification documents to `users/{uid}/notifications` with `type: 'task_assigned'`, `taskName`, `date`, `assignedBy`, `messId`, `createdAt`, `isRead: false`
    - Validate date is not a past date before writing; throw/return error if so
    - Validate all members are active before writing; throw/return error if inactive member found
    - _Requirements: 2.5, 2.7, 2.8, 8.1, 8.3, 10.1, 10.6_

  - [ ]* 2.2 Write property test for `assignTasks` — Property 4: Assignment document count equals task × member product
    - **Property 4: Assignment document count equals task × member product**
    - **Validates: Requirements 2.5**

  - [ ]* 2.3 Write property test for `assignTasks` — Property 5: Notification count equals assigned member count
    - **Property 5: Notification count equals assigned member count**
    - **Validates: Requirements 8.1, 8.3**

  - [ ] 2.4 Implement `updateTask`, `deleteTask`, `toggleComplete` methods
    - `updateTask`: update existing document fields in Firestore
    - `deleteTask`: delete document by id from `messes/{messId}/taskSchedule`
    - `toggleComplete`: update `isCompleted` field on the document
    - Validate date is not past before update/delete; return error if so
    - _Requirements: 4.2, 4.3, 4.4, 7.3, 10.6_

  - [ ] 2.5 Implement `resetMonth` method
    - Query all `taskSchedule` documents for the given month where `date >= today`
    - Delete all matching documents using `WriteBatch` (chunked at 500)
    - Do NOT delete documents where `date < today`
    - _Requirements: 5.3, 5.4_

  - [ ]* 2.6 Write property test for `resetMonth` — Property 8: Reset preserves past assignments
    - **Property 8: Reset preserves past assignments**
    - **Validates: Requirements 5.3, 5.4**

  - [ ]* 2.7 Write property test for past-date write protection — Property 3: Past-date write protection
    - **Property 3: Past-date write protection**
    - **Validates: Requirements 2.8, 4.4, 10.6**

- [ ] 3. Implement `TaskReminderChecker`
  - [ ] 3.1 Implement `shouldSendReminder` pure static method
    - Return `true` iff `now` is on the calendar day immediately before `taskDate` and `now.hour >= 23`
    - _Requirements: 9.1, 9.3_

  - [ ]* 3.2 Write property test for `shouldSendReminder` — Property 9: Reminder trigger logic
    - **Property 9: Reminder trigger logic**
    - **Validates: Requirements 9.1, 9.3**

  - [ ] 3.3 Implement `checkAndSendReminders` method
    - Query `messes/{messId}/taskSchedule` for tasks where `memberId == uid` and `date` is tomorrow
    - For each task, check if a reminder notification already exists in `users/{uid}/notifications` (avoid duplicates)
    - If `shouldSendReminder` returns `true` and no reminder exists, write reminder doc with `type: 'task_reminder'`
    - _Requirements: 9.1, 9.2, 9.3_

- [ ] 4. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement `TaskScheduleModel` serialization property test
  - [ ]* 5.1 Write property test — Property 1: TaskScheduleModel serialization round-trip
    - **Property 1: TaskScheduleModel serialization round-trip**
    - **Validates: Requirements 11.5, 11.2**
    - For any valid `TaskScheduleModel`, `fromFirestore(toFirestore(m))` must produce identical field values

- [ ] 6. Implement filter helper functions
  - [ ] 6.1 Implement `filterMyTasks` pure function
    - Accept a list of `TaskScheduleModel` and a `uid`; return only tasks where `memberId == uid` and `date` is today or tomorrow
    - _Requirements: 6.2, 6.3_

  - [ ]* 6.2 Write property test for `filterMyTasks` — Property 6: My Tasks filter correctness
    - **Property 6: My Tasks filter correctness**
    - **Validates: Requirements 6.2, 6.3**

  - [ ] 6.3 Implement `filterCompletedTasks` pure function
    - Accept a list of `TaskScheduleModel` and a `uid`; return only tasks where `memberId == uid` and `isCompleted == true`, sorted by `date` descending
    - _Requirements: 7.2_

  - [ ]* 6.4 Write property test for `filterCompletedTasks` — Property 7: Completed tasks filter and ordering
    - **Property 7: Completed tasks filter and ordering**
    - **Validates: Requirements 7.2**

  - [ ] 6.5 Implement `filterActiveMembers` pure function
    - Accept a list of member maps; return only those where `isActive == true`
    - _Requirements: 2.7, 10.4, 10.5, 11.3_

  - [ ]* 6.6 Write property test for `filterActiveMembers` — Property 2: Active members filter excludes inactive members
    - **Property 2: Active members filter excludes inactive members**
    - **Validates: Requirements 2.7, 10.4, 10.5, 11.3**

- [ ] 7. Create extracted stateless widgets
  - [ ] 7.1 Create `lib/features/task/presentation/widgets/month_selector_bar.dart`
    - Implement `MonthSelectorBar` stateless widget with `selectedMonth`, `onMonthChanged`, `isManager`, `onReset` parameters
    - Display month as `"April 2026"` with back/forward arrows and dropdown
    - Show Reset button only when `isManager == true`
    - _Requirements: 1.5, 1.6, 5.1, 5.2, 10.2_

  - [ ] 7.2 Create `lib/features/task/presentation/widgets/task_date_cell.dart`
    - Implement `TaskDateCell` stateless widget with `date`, `tasks`, `isToday`, `isPast`, `onTap` parameters
    - Apply visual states: green tint (has tasks), white (no tasks/future), grey (past), green border (today)
    - Show task icons (up to 2, then `+N` overflow) mapped from task name: cleaning→`Icons.cleaning_services`, cooking→`Icons.restaurant`, dish washing→`Icons.water_drop`, garbage→`Icons.delete_outline`, custom→`Icons.task_alt`
    - Disable tap interaction when `isPast == true`
    - _Requirements: 1.2, 1.3, 1.4_

  - [ ]* 7.3 Write property test for `TaskDateCell` — Property 10: Date cell rendering reflects task presence
    - **Property 10: Date cell rendering reflects task presence**
    - **Validates: Requirements 1.2**

  - [ ]* 7.4 Write property test for `TaskDateCell` — Property 11: Past date cells are non-editable
    - **Property 11: Past date cells are non-editable**
    - **Validates: Requirements 1.4, 3.5**

  - [ ] 7.5 Create `lib/features/task/presentation/widgets/task_calendar_grid.dart`
    - Implement `TaskCalendarGrid` stateless widget with `month`, `tasks`, `isManager`, `onDateTap` parameters
    - Render a 7-column (Sun–Sat) month grid; group tasks by date internally
    - Use `TaskDateCell` for each day cell
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ] 7.6 Create `lib/features/task/presentation/widgets/task_detail_sheet.dart`
    - Implement `showTaskDetailSheet` function showing a bottom sheet listing all tasks for a date
    - Format each entry as `{Task_Type} → {Member_Name(s)}`
    - Show "No tasks assigned" when list is empty
    - Show Edit/Remove controls per task only when `isManager == true` and date is a future date
    - Past dates render in view-only mode
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 7.7 Create `lib/features/task/presentation/widgets/task_assignment_sheet.dart`
    - Implement `showTaskAssignmentSheet` function with a multi-step bottom sheet
    - Step 1: predefined task type chips (Cleaning, Cooking, Dish Washing, Garbage) + "Add Custom" free-text option; allow multiple selection
    - Step 2: member checkboxes with avatar initials, active members only; allow multiple selection
    - Support edit mode when `existing` is non-null (pre-populate selections)
    - Call `onConfirm(taskNames, memberIds, memberNames)` on confirmation
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.1, 10.7_

  - [ ] 7.8 Create `lib/features/task/presentation/widgets/my_tasks_tab.dart`
    - Implement `MyTasksTab` stateless widget with `tasks`, `currentUid`, `messId`, `onToggleComplete` parameters
    - Filter tasks using `filterMyTasks` helper; group into "Today" and "Tomorrow" sections
    - Show "No tasks" placeholder when a section is empty
    - Show completion toggle for each task
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ] 7.9 Create `lib/features/task/presentation/widgets/completed_tasks_tab.dart`
    - Implement `CompletedTasksTab` stateless widget with `tasks`, `currentUid` parameters
    - Filter tasks using `filterCompletedTasks` helper
    - Show "No completed tasks" placeholder when empty
    - _Requirements: 7.1, 7.2, 7.4_

- [ ] 8. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Rebuild `TaskSchedulePage` with calendar UI and real-time stream
  - Replace `lib/features/task/presentation/pages/task_schedule_page.dart` with the full implementation
  - In `initState`: load user profile (uid, messId, role, userName) and members list (filtered by `isActive == true`) once
  - Open a `Stream<QuerySnapshot>` on `messes/{messId}/taskSchedule` filtered to the selected month; replace stream when `_selectedMonth` changes via `setState`
  - Use `StreamBuilder<QuerySnapshot>` to rebuild `TaskCalendarGrid` and bottom tabs on every Firestore emission
  - Implement `_onMonthChanged`, `_openAssignmentSheet`, `_openDetailSheet`, `_resetMonth` methods
  - Show FAB (`+`) only when `_isManager == true`; FAB opens `showTaskAssignmentSheet`
  - Show bottom tab row with "My Tasks" and "Completed Tasks" tabs
  - Handle "Not in a mess" empty state when `messId` is empty
  - Wrap all Firestore operations in `try/catch`; surface errors via `ScaffoldMessenger` snack bars
  - _Requirements: 1.1, 1.5, 1.6, 2.1, 2.6, 3.1, 4.2, 4.3, 5.1, 5.5, 6.1, 7.1, 10.1, 10.2, 10.3, 11.1_

- [ ] 10. Integrate `TaskReminderChecker` into app launch
  - In `DashboardPage.initState` (or equivalent authenticated entry point), call `TaskReminderChecker().checkAndSendReminders(...)` as fire-and-forget (do not `await`)
  - Ensure UI is not blocked
  - _Requirements: 9.1, 9.2_

- [ ] 11. Final Checkpoint — Ensure all tests pass, ask the user if questions arise.

## Notes

- Sub-tasks marked with `*` are optional and can be skipped for a faster MVP
- Property tests use the [glados](https://pub.dev/packages/glados) library; each test runs a minimum of 100 iterations
- `TaskScheduleService` and `TaskReminderChecker` have no Flutter dependency — they are pure Dart classes, making them straightforward to unit and property test
- Filter helpers (`filterMyTasks`, `filterCompletedTasks`, `filterActiveMembers`) are pure functions — extract them to a shared utils file or co-locate with their respective widgets
- All write operations go through `TaskScheduleService`; the Firestore stream handles UI refresh automatically — no manual `setState` needed after writes
- Follow `AppColors.primaryGreen` / `AppColors.bgColor` / `AppColors.textDark` for all color usage
- Follow existing `StatefulWidget` + `StreamBuilder` pattern; no Provider/Bloc
