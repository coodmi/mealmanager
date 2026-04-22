# Requirements Document

## Introduction

The Task Schedule (Smart Duty Management) feature enables mess managers to assign daily household duties — such as Cleaning, Cooking, Dish Washing, and Garbage disposal — to mess members on a per-day basis. Members can view their upcoming and past tasks, mark tasks as completed, and receive notifications when assigned. The feature replaces the existing basic list-view task page with a full calendar-based schedule UI, consistent with the existing Bazar Schedule design language.

---

## Glossary

- **Task_Schedule_System**: The complete feature described in this document, covering assignment, display, editing, and notifications for daily mess duties.
- **Manager**: A mess member with the role `manager` who has full create, edit, and delete access to task assignments.
- **Member**: A mess member with the role `member` who can view tasks and mark their own tasks as completed.
- **Active_Member**: A mess member whose `isActive` field in `messes/{messId}/members` is `true`.
- **Inactive_Member**: A mess member whose `isActive` field is `false` or who has been removed from the mess.
- **Task_Assignment**: A single record in `messes/{messId}/taskSchedule` linking one task type to one member for one date.
- **Task_Type**: A named category of duty. Predefined types are: Cleaning, Cooking, Dish Washing, Garbage. Custom types may be defined by the Manager.
- **Calendar_View**: The full-month grid display showing all days of the selected month with task indicators.
- **Date_Cell**: A single day cell within the Calendar_View.
- **Selected_Month**: The month currently displayed in the Calendar_View, controlled by the month selector.
- **Past_Date**: Any date strictly before today's date (local device time).
- **Future_Date**: Any date on or after today's date.
- **Detail_Popup**: A bottom sheet or dialog shown when a user taps a Date_Cell, listing all Task_Assignments for that date.
- **My_Tasks_Tab**: The bottom tab showing today's and tomorrow's Task_Assignments for the currently logged-in Member.
- **Completed_Tasks_Tab**: The bottom tab showing Task_Assignments marked as `isCompleted = true` for the current Member.
- **Notification**: A document written to `users/{uid}/notifications` in Firestore.
- **Reminder_Notification**: A Notification sent the day before a Task_Assignment date at 11 PM local time.
- **FAB**: The floating action button (`+`) for quick task assignment, visible to Managers only.
- **Reset**: A Manager action that removes all Task_Assignments for the Selected_Month that fall on Future_Dates.

---

## Requirements

### Requirement 1: Calendar View Display

**User Story:** As a mess member, I want to see a full-month calendar showing who is assigned to which tasks on each day, so that I can quickly understand the duty schedule at a glance.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL display a Calendar_View showing all days of the Selected_Month in a grid layout.
2. WHEN a Date_Cell has one or more Task_Assignments, THE Task_Schedule_System SHALL render that Date_Cell with a green indicator (AppColors.primaryGreen) and show task icons (e.g., cooking pan, broom) with assigned member names.
3. WHEN a Date_Cell has no Task_Assignments, THE Task_Schedule_System SHALL render that Date_Cell with a white/neutral (available) indicator.
4. WHEN a Date_Cell corresponds to a Past_Date, THE Task_Schedule_System SHALL render that Date_Cell in grey and disable all edit interactions for that cell.
5. THE Task_Schedule_System SHALL display a month selector at the top of the screen showing the current Selected_Month (e.g., "April 2026") with a dropdown arrow to change the month.
6. WHEN the user changes the Selected_Month via the month selector, THE Task_Schedule_System SHALL reload and display Task_Assignments for the newly selected month.

---

### Requirement 2: Task Assignment (Manager)

**User Story:** As a manager, I want to assign one or multiple tasks to one or multiple members for a specific date, so that duties are clearly distributed across the mess.

#### Acceptance Criteria

1. WHEN a Manager taps a Future_Date cell or the FAB button, THE Task_Schedule_System SHALL open an assignment bottom sheet allowing the Manager to select a date, one or more Task_Types, and one or more Active_Members.
2. THE Task_Schedule_System SHALL present the following predefined Task_Types for selection: Cleaning, Cooking, Dish Washing, Garbage.
3. WHERE the Manager selects "Add New Task", THE Task_Schedule_System SHALL allow the Manager to enter a custom task name as a free-text field.
4. THE Task_Schedule_System SHALL allow the Manager to select multiple Active_Members per Task_Type using checkboxes with member avatars.
5. WHEN the Manager confirms the assignment, THE Task_Schedule_System SHALL write one Task_Assignment document per (task, member) combination to `messes/{messId}/taskSchedule` with fields: `taskName`, `memberId`, `memberName`, `date`, `messId`, `isCompleted: false`, `createdAt`.
6. WHEN the Manager confirms the assignment, THE Task_Schedule_System SHALL update the Calendar_View to reflect the new assignments without requiring a full page reload.
7. IF the Manager attempts to assign a task to an Inactive_Member, THEN THE Task_Schedule_System SHALL display an error message and prevent the assignment from being saved.
8. IF the Manager attempts to assign a task to a Past_Date, THEN THE Task_Schedule_System SHALL display an error message and prevent the assignment from being saved.

---

### Requirement 3: Task Detail View

**User Story:** As a mess member, I want to tap on a date in the calendar and see all tasks and their assigned members for that day, so that I can get a clear breakdown of duties.

#### Acceptance Criteria

1. WHEN a user taps a Date_Cell, THE Task_Schedule_System SHALL display a Detail_Popup listing all Task_Assignments for that date.
2. THE Task_Schedule_System SHALL format each entry in the Detail_Popup as: `{Task_Type} → {Member_Name(s)}` (e.g., "Cooking → Rony, Rakib").
3. WHEN a Date_Cell has no Task_Assignments, THE Task_Schedule_System SHALL display a "No tasks assigned" message in the Detail_Popup.
4. WHEN the Detail_Popup is shown for a Future_Date and the user is a Manager, THE Task_Schedule_System SHALL display Edit and Remove action controls for each Task_Assignment.
5. WHEN the Detail_Popup is shown for a Past_Date, THE Task_Schedule_System SHALL display Task_Assignments in view-only mode with no edit or remove controls.

---

### Requirement 4: Task Editing and Removal (Manager)

**User Story:** As a manager, I want to edit or remove task assignments on future dates, so that I can correct mistakes or update the schedule as plans change.

#### Acceptance Criteria

1. WHEN a Manager selects Edit on a Task_Assignment in the Detail_Popup for a Future_Date, THE Task_Schedule_System SHALL open the assignment bottom sheet pre-populated with the existing task and member selections.
2. WHEN a Manager confirms an edit, THE Task_Schedule_System SHALL update the corresponding Task_Assignment documents in Firestore and refresh the Calendar_View.
3. WHEN a Manager selects Remove on a Task_Assignment in the Detail_Popup for a Future_Date, THE Task_Schedule_System SHALL delete the corresponding Task_Assignment document from Firestore and refresh the Calendar_View.
4. IF a Manager attempts to edit or remove a Task_Assignment on a Past_Date, THEN THE Task_Schedule_System SHALL display an error message and prevent the operation.

---

### Requirement 5: Reset Month (Manager)

**User Story:** As a manager, I want to reset all task assignments for the current month's future dates, so that I can start the schedule fresh without losing historical records.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL display a Reset button in the top section of the screen, visible only to Managers.
2. WHEN a Manager taps the Reset button, THE Task_Schedule_System SHALL display a confirmation dialog before proceeding.
3. WHEN a Manager confirms the Reset action, THE Task_Schedule_System SHALL delete all Task_Assignment documents for the Selected_Month where the date is a Future_Date.
4. WHEN a Manager confirms the Reset action, THE Task_Schedule_System SHALL NOT delete Task_Assignment documents for Past_Dates within the Selected_Month.
5. WHEN the Reset operation completes, THE Task_Schedule_System SHALL refresh the Calendar_View to reflect the cleared assignments.

---

### Requirement 6: My Tasks Tab

**User Story:** As a mess member, I want to see my own tasks for today and tomorrow in a dedicated tab, so that I can quickly know what I need to do without browsing the full calendar.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL display a "My Tasks" tab in the bottom section of the screen, visible to all users.
2. WHEN the "My Tasks" tab is active, THE Task_Schedule_System SHALL display all Task_Assignments for the current user for today, grouped under a "Today" section.
3. WHEN the "My Tasks" tab is active, THE Task_Schedule_System SHALL display all Task_Assignments for the current user for tomorrow, grouped under a "Tomorrow" section.
4. WHEN the current user has no Task_Assignments for today or tomorrow, THE Task_Schedule_System SHALL display a "No tasks" placeholder message for the respective section.

---

### Requirement 7: Completed Tasks Tab

**User Story:** As a mess member, I want to view my completed tasks in a dedicated tab, so that I can track my contribution history.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL display a "Completed Tasks" tab in the bottom section of the screen, visible to all users.
2. WHEN the "Completed Tasks" tab is active, THE Task_Schedule_System SHALL display all Task_Assignments for the current user where `isCompleted` is `true`, ordered by date descending.
3. WHEN a Member taps the completion toggle on their own Task_Assignment, THE Task_Schedule_System SHALL update the `isCompleted` field to `true` in Firestore and move the task to the Completed_Tasks_Tab.
4. WHEN the current user has no completed Task_Assignments, THE Task_Schedule_System SHALL display a "No completed tasks" placeholder message.

---

### Requirement 8: Assignment Notification

**User Story:** As a mess member, I want to receive a notification when I am assigned a task, so that I am immediately aware of my new duty.

#### Acceptance Criteria

1. WHEN a Manager saves a new Task_Assignment, THE Task_Schedule_System SHALL write a Notification document to `users/{assignedMemberId}/notifications` with fields: `type: 'task_assigned'`, `taskName`, `date`, `assignedBy`, `messId`, `createdAt`, `isRead: false`.
2. WHEN a Manager saves a new Task_Assignment, THE Task_Schedule_System SHALL also write a manager activity entry to the home top bar notification feed so it appears instantly.
3. THE Task_Schedule_System SHALL write one Notification document per assigned member per Task_Assignment.

---

### Requirement 9: Reminder Notification

**User Story:** As a mess member, I want to receive a reminder notification the evening before my assigned task day, so that I do not forget my duty.

#### Acceptance Criteria

1. WHEN the current device time reaches 11 PM on the day before a Task_Assignment date, THE Task_Schedule_System SHALL write a Reminder_Notification document to `users/{assignedMemberId}/notifications` with fields: `type: 'task_reminder'`, `taskName`, `date`, `messId`, `createdAt`, `isRead: false`.
2. THE Reminder_Notification SHALL be visible in the Home > Profile > MyRequest Menu notifications section for the assigned member.
3. IF a Task_Assignment is removed before the reminder time, THEN THE Task_Schedule_System SHALL NOT send the Reminder_Notification for that assignment.

---

### Requirement 10: Access Control and Restriction Rules

**User Story:** As a system, I want to enforce role-based access and business rules, so that only authorized users can modify the schedule and invalid assignments are prevented.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL restrict task assignment, editing, and deletion operations to users with the `manager` role.
2. THE Task_Schedule_System SHALL restrict the Reset button and FAB button visibility to users with the `manager` role.
3. WHEN a Member (non-manager) attempts to perform a write operation, THE Task_Schedule_System SHALL display a permission-denied message and abort the operation.
4. IF a member's `isActive` field is `false` in `messes/{messId}/members`, THEN THE Task_Schedule_System SHALL exclude that member from the assignable members list and display them as unavailable.
5. IF a member has been removed from the mess, THEN THE Task_Schedule_System SHALL exclude that member from the assignable members list.
6. THE Task_Schedule_System SHALL prevent any write operation (assign, edit, delete) targeting a Past_Date and display an appropriate error message.
7. WHEN a date already has Task_Assignments and a Manager opens the assignment sheet for that date, THE Task_Schedule_System SHALL pre-populate the existing assignments and allow the Manager to modify them (lock-then-edit pattern).

---

### Requirement 11: Data Model Compatibility

**User Story:** As a developer, I want the new feature to use and extend the existing Firestore data model, so that existing data is not lost and the codebase remains consistent.

#### Acceptance Criteria

1. THE Task_Schedule_System SHALL read and write Task_Assignment documents from/to the existing `messes/{messId}/taskSchedule` Firestore collection.
2. THE Task_Schedule_System SHALL use the existing `TaskScheduleModel` fields: `taskName`, `memberId`, `memberName`, `date`, `messId`, `isCompleted`, `createdAt`.
3. THE Task_Schedule_System SHALL query members from `messes/{messId}/members` and filter by `isActive: true` when building the assignable members list.
4. THE Task_Schedule_System SHALL write Notification documents to `users/{uid}/notifications` consistent with the existing notification schema used elsewhere in the app.
5. FOR ALL Task_Assignment documents written by the Task_Schedule_System, parsing the document back into a `TaskScheduleModel` and re-serializing it SHALL produce an equivalent Firestore document (round-trip property).
