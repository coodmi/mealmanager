# Design Document: Smart Task Schedule

## Overview

The Smart Task Schedule feature replaces the existing basic list-view `TaskSchedulePage` with a full calendar-based duty management UI. Managers can assign predefined or custom task types (Cleaning, Cooking, Dish Washing, Garbage) to one or more mess members on specific dates. Members can view the monthly calendar, see their personal tasks in a dedicated tab, mark tasks complete, and receive Firestore-based notifications on assignment and the evening before their duty day.

The design follows the same visual language as `BazarSchedulePage` — `AppColors.primaryGreen` accents, rounded cards, floating action button — while introducing a 7-column month grid, a bottom tab section, and a multi-step assignment bottom sheet.

---

## Architecture

The feature uses a single `StatefulWidget` page (`TaskSchedulePage`) with Firestore real-time streams for live updates. No external state management package (Provider/Bloc/Riverpod) is introduced; state is held in the widget's `State` class, consistent with the rest of the codebase.

```
TaskSchedulePage (StatefulWidget)
│
├── _TaskSchedulePageState
│   ├── Stream<QuerySnapshot> _taskStream   ← live Firestore stream for selected month
│   ├── DateTime _selectedMonth             ← drives calendar + stream query
│   ├── String _currentUid / _messId / _role
│   ├── List<MemberModel> _members          ← loaded once on init
│   └── int _bottomTabIndex                 ← 0 = My Tasks, 1 = Completed
│
├── Widgets (extracted, stateless)
│   ├── TaskCalendarGrid
│   ├── TaskDateCell
│   ├── MonthSelectorBar
│   ├── TaskDetailSheet (bottom sheet)
│   ├── TaskAssignmentSheet (bottom sheet)
│   └── MyTasksTab / CompletedTasksTab
│
└── Services / Helpers
    ├── TaskScheduleService   ← Firestore CRUD + notification writes
    └── TaskReminderChecker   ← client-side reminder logic (pure function)
```

### Data Flow

1. On `initState`, load user profile (uid, messId, role) and members list once.
2. Open a `Stream<QuerySnapshot>` on `messes/{messId}/taskSchedule` filtered to the selected month.
3. `StreamBuilder` rebuilds `TaskCalendarGrid` and bottom tabs whenever Firestore emits.
4. Write operations (assign, edit, delete, reset) go through `TaskScheduleService`, which also writes notification documents atomically using a Firestore `WriteBatch`.

---

## Components and Interfaces

### TaskSchedulePage

Top-level page widget. Owns all state.

```dart
class TaskSchedulePage extends StatefulWidget { ... }

class _TaskSchedulePageState extends State<TaskSchedulePage> {
  late Stream<QuerySnapshot> _taskStream;
  DateTime _selectedMonth;          // first day of displayed month
  String _messId, _currentUid, _currentUserName;
  bool _isManager;
  List<Map<String, dynamic>> _members;  // {id, name, isActive, avatarUrl?}
  int _bottomTabIndex;              // 0 = My Tasks, 1 = Completed

  void _onMonthChanged(DateTime newMonth);
  void _openAssignmentSheet({DateTime? date, TaskScheduleModel? existing});
  void _openDetailSheet(DateTime date, List<TaskScheduleModel> tasks);
  Future<void> _resetMonth();
}
```

### MonthSelectorBar

Stateless widget. Displays `"April 2026"` with back-arrow and dropdown. Calls `onMonthChanged` callback.

```dart
class MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isManager;
  final VoidCallback onReset;
}
```

### TaskCalendarGrid

Stateless widget. Renders a 7-column (Sun–Sat) month grid. Receives the full task list for the month and groups them by date internally.

```dart
class TaskCalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<TaskScheduleModel> tasks;
  final bool isManager;
  final void Function(DateTime, List<TaskScheduleModel>) onDateTap;
}
```

### TaskDateCell

Stateless widget. Renders a single day cell.

```dart
class TaskDateCell extends StatelessWidget {
  final DateTime date;
  final List<TaskScheduleModel> tasks;   // tasks for this specific date
  final bool isToday;
  final bool isPast;
  final VoidCallback onTap;
}
```

Cell visual states:

| Condition | Background | Border |
|---|---|---|
| Has tasks | `AppColors.primaryGreen` (light tint) | none |
| No tasks, future | `Colors.white` | light grey |
| Past date | `Colors.grey.shade200` | none |
| Today | `Colors.white` | `AppColors.primaryGreen` 2px |

Task icons shown inside cell (up to 2, then `+N` overflow):

| Task Name (case-insensitive match) | Icon |
|---|---|
| cleaning | `Icons.cleaning_services` |
| cooking | `Icons.restaurant` |
| dish washing / dishes | `Icons.water_drop` |
| garbage | `Icons.delete_outline` |
| custom | `Icons.task_alt` |

### TaskDetailSheet

Bottom sheet shown on date tap. Lists all tasks for the date. Manager sees Edit/Remove per task on future dates; past dates are view-only.

```dart
void showTaskDetailSheet(
  BuildContext context, {
  required DateTime date,
  required List<TaskScheduleModel> tasks,
  required bool isManager,
  required VoidCallback onEdit,
  required VoidCallback onRemove,
});
```

### TaskAssignmentSheet

Multi-step bottom sheet for creating/editing assignments.

Step 1 — Task type selection (predefined list + "Add Custom" option).  
Step 2 — Member selection (checkboxes with avatar initials, active members only).

```dart
void showTaskAssignmentSheet(
  BuildContext context, {
  required DateTime date,
  required List<Map<String, dynamic>> members,
  required bool isManager,
  TaskScheduleModel? existing,           // non-null = edit mode
  required Future<void> Function(
    String taskName,
    List<String> memberIds,
    List<String> memberNames,
  ) onConfirm,
});
```

### MyTasksTab

Stateless widget. Filters the full task stream to `memberId == currentUid` and `date == today || date == tomorrow`. Groups into "Today" and "Tomorrow" sections with completion toggle.

### CompletedTasksTab

Stateless widget. Filters to `memberId == currentUid && isCompleted == true`, sorted by date descending.

### TaskScheduleService

Pure Dart class (no Flutter dependency). Handles all Firestore writes.

```dart
class TaskScheduleService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Writes N×M Task_Assignment documents + N×M notification documents in a batch.
  Future<void> assignTasks({
    required String messId,
    required List<String> taskNames,
    required List<({String id, String name})> members,
    required DateTime date,
    required String assignedByName,
  });

  /// Updates an existing Task_Assignment document.
  Future<void> updateTask(String messId, TaskScheduleModel updated);

  /// Deletes a single Task_Assignment document.
  Future<void> deleteTask(String messId, String taskId);

  /// Deletes all future Task_Assignment documents in the given month.
  Future<void> resetMonth(String messId, DateTime month);

  /// Toggles isCompleted on a Task_Assignment.
  Future<void> toggleComplete(String messId, TaskScheduleModel task);
}
```

### TaskReminderChecker

Pure Dart class with no Firestore dependency. Called on app open to check whether any reminder notifications need to be written.

```dart
class TaskReminderChecker {
  /// Returns true if [now] is on the day before [taskDate] and at or after 23:00 local time.
  static bool shouldSendReminder(DateTime taskDate, DateTime now);

  /// Queries upcoming tasks for the current user and writes reminder notifications
  /// for any task whose reminder has not yet been sent.
  Future<void> checkAndSendReminders({
    required String messId,
    required String uid,
    required DateTime now,
  });
}
```

---

## Data Models

### TaskScheduleModel (existing — no changes)

```
messes/{messId}/taskSchedule/{docId}
  taskName:   String
  memberId:   String
  memberName: String
  date:       Timestamp
  messId:     String
  isCompleted: bool
  createdAt:  Timestamp
```

### Notification Document

```
users/{uid}/notifications/{docId}
  type:        'task_assigned' | 'task_reminder'
  taskName:    String
  date:        Timestamp
  assignedBy:  String          // manager display name (task_assigned only)
  messId:      String
  createdAt:   Timestamp
  isRead:      bool
```

### Member (read from Firestore, not persisted separately)

```
messes/{messId}/members/{uid}
  name:     String
  isActive: bool
  role:     'manager' | 'member'
```

### Firestore Indexes Required

- `messes/{messId}/taskSchedule`: composite index on `(date ASC, memberId ASC)` for My Tasks queries.
- `users/{uid}/notifications`: composite index on `(isRead ASC, createdAt DESC)` (likely already exists).

---

## State Management Approach

`_TaskSchedulePageState` holds all mutable state. The Firestore stream is the single source of truth for task data:

```dart
_taskStream = FirebaseFirestore.instance
    .collection('messes')
    .doc(_messId)
    .collection('taskSchedule')
    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthStart))
    .where('date', isLessThan: Timestamp.fromDate(_monthEnd))
    .snapshots();
```

`StreamBuilder<QuerySnapshot>` wraps the calendar grid and bottom tabs. When `_selectedMonth` changes, `setState` replaces `_taskStream` with a new query — Flutter's `StreamBuilder` automatically unsubscribes from the old stream.

Write operations call `TaskScheduleService` methods which update Firestore; the stream emits the change and the UI rebuilds automatically. No manual `setState` is needed after writes.

---

## Navigation Flow

```
DashboardPage
  └─ (bottom nav: Tasks tab)
       └─ TaskSchedulePage
            ├─ MonthSelectorBar (inline, no navigation)
            ├─ TaskCalendarGrid
            │    └─ tap date → TaskDetailSheet (bottom sheet)
            │         └─ tap Edit → TaskAssignmentSheet (bottom sheet, edit mode)
            ├─ FAB (+) → TaskAssignmentSheet (bottom sheet, create mode)
            └─ Bottom tabs
                 ├─ MyTasksTab (inline)
                 └─ CompletedTasksTab (inline)
```

No new named routes are required. All sub-views are bottom sheets or inline tab content within `TaskSchedulePage`.

---

## Notification Delivery Mechanism

Notifications are Firestore documents, not push notifications. Delivery is client-side:

**Assignment notifications** — written synchronously in the same `WriteBatch` as the task assignment documents. The assigned member sees the notification the next time they open the app and the notification feed refreshes.

**Reminder notifications** — written by `TaskReminderChecker.checkAndSendReminders()`, called once on app open (in `DashboardPage.initState` or equivalent). The checker:

1. Queries `messes/{messId}/taskSchedule` for tasks belonging to the current user where `date` is tomorrow.
2. For each such task, checks whether a reminder notification already exists in `users/{uid}/notifications` (to avoid duplicates).
3. If no reminder exists and `shouldSendReminder(taskDate, now)` returns `true` (i.e., it is currently ≥ 23:00 the day before), writes the reminder document.

`shouldSendReminder` is a pure function:

```dart
static bool shouldSendReminder(DateTime taskDate, DateTime now) {
  final dayBefore = taskDate.subtract(const Duration(days: 1));
  return now.year == dayBefore.year &&
         now.month == dayBefore.month &&
         now.day == dayBefore.day &&
         now.hour >= 23;
}
```

If a task is deleted before the reminder fires, the checker finds no matching task and writes nothing — satisfying Requirement 9.3.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Property-based testing is applicable here because the feature contains pure transformation and filtering functions (serialization, date classification, member filtering, task filtering, reminder logic) whose correctness must hold across a wide range of inputs.

### Property 1: TaskScheduleModel serialization round-trip

*For any* valid `TaskScheduleModel` (with arbitrary `taskName`, `memberId`, `memberName`, `date`, `messId`, `isCompleted`, `createdAt`), calling `TaskScheduleModel.fromFirestore` on the result of `toFirestore()` SHALL produce a model with identical field values.

**Validates: Requirements 11.5, 11.2**

---

### Property 2: Active members filter excludes inactive members

*For any* list of member records with mixed `isActive` values, the assignable members list produced by the system SHALL contain only those members where `isActive == true`.

**Validates: Requirements 2.7, 10.4, 10.5, 11.3**

---

### Property 3: Past-date write protection

*For any* date strictly before today (local device time), any attempt to save, edit, or delete a `Task_Assignment` targeting that date SHALL be rejected and no Firestore write SHALL occur.

**Validates: Requirements 2.8, 4.4, 10.6**

---

### Property 4: Assignment document count equals task × member product

*For any* list of N task names and M member IDs passed to `TaskScheduleService.assignTasks`, exactly N × M `Task_Assignment` documents SHALL be written to `messes/{messId}/taskSchedule`.

**Validates: Requirements 2.5**

---

### Property 5: Notification count equals assigned member count

*For any* call to `TaskScheduleService.assignTasks` with M members, exactly M notification documents of type `'task_assigned'` SHALL be written to the respective `users/{uid}/notifications` collections.

**Validates: Requirements 8.1, 8.3**

---

### Property 6: My Tasks filter correctness

*For any* list of `TaskScheduleModel` objects, the My Tasks filter function SHALL return exactly those models where `memberId` equals the current user's UID and `date` falls on today or tomorrow — no more, no less.

**Validates: Requirements 6.2, 6.3**

---

### Property 7: Completed tasks filter and ordering

*For any* list of `TaskScheduleModel` objects, the Completed Tasks filter function SHALL return exactly those models where `memberId` equals the current user's UID and `isCompleted == true`, and the result SHALL be ordered by `date` descending.

**Validates: Requirements 7.2**

---

### Property 8: Reset preserves past assignments

*For any* set of `Task_Assignment` documents in a given month containing a mix of past-dated and future-dated records, after `TaskScheduleService.resetMonth` completes, all past-dated assignments SHALL still exist and all future-dated assignments SHALL be deleted.

**Validates: Requirements 5.3, 5.4**

---

### Property 9: Reminder trigger logic

*For any* `TaskScheduleModel` with a given `date`, `TaskReminderChecker.shouldSendReminder(taskDate, now)` SHALL return `true` if and only if `now` falls on the calendar day immediately before `taskDate` and `now.hour >= 23`.

**Validates: Requirements 9.1, 9.3**

---

### Property 10: Date cell rendering reflects task presence

*For any* non-empty list of `TaskScheduleModel` objects for a given date, the `TaskDateCell` widget rendered for that date SHALL display the `AppColors.primaryGreen` background tint and include at least one task icon.

**Validates: Requirements 1.2**

---

### Property 11: Past date cells are non-editable

*For any* date strictly before today, the `TaskDateCell` rendered for that date SHALL use grey styling and SHALL NOT expose any edit interaction (no tap-to-assign, no edit/remove controls in the detail sheet).

**Validates: Requirements 1.4, 3.5**

---

## Error Handling

| Scenario | Handling |
|---|---|
| Firestore write fails | Show `SnackBar` with red background and retry option |
| User has no `messId` | Show "Not in a mess" empty state, disable all interactions |
| Member list empty | Show "No members found" in assignment sheet |
| Assignment to inactive member | Validate before write; show error snack, abort |
| Assignment to past date | Validate before write; show error snack, abort |
| Non-manager write attempt | Call `showNoPermissionSnack(context)` from `permission_utils.dart`, abort |
| Stream error | Show inline error widget with refresh button |
| Reminder duplicate | Check for existing reminder doc before writing; skip if found |

All Firestore operations are wrapped in `try/catch`. Errors are surfaced via `ScaffoldMessenger` snack bars consistent with the existing codebase pattern.

---

## Testing Strategy

### Unit Tests (example-based)

- `TaskScheduleModel.fromFirestore` / `toFirestore` with known fixture data
- `TaskReminderChecker.shouldSendReminder` with specific date/time pairs (boundary: exactly 23:00, 22:59, midnight)
- `TaskScheduleService.assignTasks` with mocked Firestore — verify batch write calls
- `TaskScheduleService.resetMonth` with mocked Firestore — verify only future docs are deleted
- Role-based access: verify non-manager calls to service methods throw/return error
- Empty state rendering: "No tasks assigned", "No tasks", "No completed tasks" messages

### Property-Based Tests (using `fast_check` or `dart_test` with custom generators)

Each property test runs a minimum of **100 iterations** with randomly generated inputs.

Tag format: `// Feature: task-schedule, Property N: <property text>`

| Property | Generator | Assertion |
|---|---|---|
| P1: Serialization round-trip | Random `TaskScheduleModel` (arbitrary strings, dates, booleans) | `fromFirestore(toFirestore(m))` fields equal `m` fields |
| P2: Active members filter | Random member list with random `isActive` values | Result contains only `isActive == true` members |
| P3: Past-date write protection | Random date in range `[epoch, today - 1 day]` | Service rejects write, no Firestore call made |
| P4: Assignment document count | Random N task names (1–5), M member IDs (1–10) | Exactly N×M documents written |
| P5: Notification count | Random M member IDs (1–10) | Exactly M notification docs written |
| P6: My Tasks filter | Random task list with random memberIds and dates | Filter returns exactly matching tasks |
| P7: Completed tasks filter + order | Random task list with random `isCompleted` and dates | Filter returns correct subset in descending date order |
| P8: Reset preserves past | Random task list with mixed past/future dates | Past tasks remain, future tasks deleted |
| P9: Reminder trigger logic | Random `taskDate` and `now` combinations | `shouldSendReminder` returns true iff day-before at ≥ 23:00 |
| P10: Cell rendering with tasks | Random non-empty task list for a date | Cell has green tint and at least one icon |
| P11: Past cell non-editable | Random past date | Cell uses grey styling, no edit controls |

### Integration Tests

- Verify Firestore collection path `messes/{messId}/taskSchedule` is correctly targeted
- Verify notification documents are written to `users/{uid}/notifications` with correct schema
- Verify member query applies `isActive == true` filter
- End-to-end: assign task → calendar updates → notification appears in feed
