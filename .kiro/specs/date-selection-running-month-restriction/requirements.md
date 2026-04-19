# Requirements Document

## Introduction

এই ফিচারটি নিশ্চিত করে যে অ্যাপের রিপোর্ট পেজ বাদে সকল ডেট পিকারে শুধুমাত্র "রানিং মাস"-এর তারিখ সিলেক্ট করা যাবে। "রানিং মাস" ক্যালেন্ডারের বর্তমান মাস নয়, বরং সিস্টেমের active/open মাস দিয়ে নির্ধারিত হয়। Home > Top bar থেকে যে মাসে switch করা হবে, সেটাই সেই মুহূর্তে রানিং মাস হিসেবে গণ্য হবে। Month Close না করলে পুরনো মাসও রানিং মাস হিসেবে থাকবে।

## Glossary

- **Date_Picker**: Flutter-এর `showDatePicker` বা `AppDatePicker.show` ব্যবহার করে তৈরি তারিখ নির্বাচন UI কম্পোনেন্ট।
- **Running_Month**: সিস্টেমের বর্তমান active/open মাস। `ActiveMonthService` থেকে নির্ধারিত হয়। ক্যালেন্ডারের বর্তমান মাস নয়।
- **Month_Close**: Manager কর্তৃক একটি মাসের হিসাব চূড়ান্ত করার প্রক্রিয়া। Close হলে `messes/{messId}/monthSummaries/{monthKey}` তে document তৈরি হয়।
- **Active_Month_Service**: `lib/core/services/active_month_service.dart` — সিস্টেমের running month key ও date range নির্ধারণ করে।
- **App_Date_Picker**: `lib/core/utils/app_date_picker.dart` — running month-এ সীমাবদ্ধ centralized date picker utility।
- **Selected_Month_Context**: Home > Top bar থেকে user যে মাসে switch করেছে সেই মাসের তথ্য, যা date picker-এ running month হিসেবে ব্যবহৃত হয়।
- **Report_Page**: `lib/features/reports/presentation/pages/reports_pdf_page.dart` — এই পেজে date restriction প্রযোজ্য নয়।
- **Mess_Settings_Page**: `lib/features/menu/presentation/pages/mess_settings_page.dart` — Month Close অপারেশন এখানে সম্পন্ন হয়।

---

## Requirements

### Requirement 1: Running Month নির্ধারণ

**User Story:** As a mess manager, I want the system to determine the running month based on the active/open month status, so that date restrictions reflect the actual operational month rather than the calendar month.

#### Acceptance Criteria

1. WHEN `Active_Month_Service` queries the running month for a given `messId`, THE `Active_Month_Service` SHALL return the current calendar month key (e.g., `"2026-04"`) if no `monthSummaries` document exists for that month.
2. WHEN a `monthSummaries` document exists for the current calendar month (indicating Month_Close), THE `Active_Month_Service` SHALL return the next calendar month key as the running month key.
3. THE `Active_Month_Service` SHALL return a `DateTimeRange` where `start` is the first day of the running month and `end` is the last day of the running month.
4. IF the Firestore query fails, THEN THE `Active_Month_Service` SHALL return the current calendar month key as a fallback.
5. FOR ALL valid `messId` values, the running month key returned by `Active_Month_Service` SHALL follow the format `"YYYY-MM"`.

---

### Requirement 2: Selected Month Context (Top Bar Month Switch)

**User Story:** As a mess member, I want to switch to a previous month from the Home top bar, so that I can view and enter data for that month with its full date range available.

#### Acceptance Criteria

1. WHEN a user switches to a previous month via the Home > Top bar, THE `Dashboard_Page` SHALL update the `Selected_Month_Context` to the switched month.
2. WHILE a `Selected_Month_Context` is active (user has switched month), THE `App_Date_Picker` SHALL use the `Selected_Month_Context` month's date range instead of the `Active_Month_Service` result.
3. WHEN the user returns to the default view (no month switch active), THE `App_Date_Picker` SHALL revert to using the `Active_Month_Service` result for the running month range.
4. THE `Selected_Month_Context` SHALL be passed down to all child pages (Meal, Expense, Deposit, etc.) that contain a `Date_Picker`.

---

### Requirement 3: Date Picker Restriction — Non-Report Pages

**User Story:** As a mess member, I want date pickers outside the report page to only allow dates within the running month, so that I cannot accidentally enter data for past or future months.

#### Acceptance Criteria

1. THE `App_Date_Picker` SHALL set `firstDate` to the first day of the running month and `lastDate` to the last day of the running month.
2. WHEN a user attempts to navigate to a previous month in the `Date_Picker` calendar UI, THE `Date_Picker` SHALL disable navigation beyond the running month's first day.
3. WHEN a user attempts to navigate to a future month in the `Date_Picker` calendar UI, THE `Date_Picker` SHALL disable navigation beyond the running month's last day.
4. IF an `initialDate` passed to `App_Date_Picker` falls outside the running month range, THEN THE `App_Date_Picker` SHALL clamp the `initialDate` to the nearest valid date within the running month.
5. FOR ALL `Date_Picker` instances in non-report pages, the selected date SHALL satisfy: `firstDayOfRunningMonth <= selectedDate <= lastDayOfRunningMonth`.

---

### Requirement 4: Report Page Exception

**User Story:** As a mess manager, I want the report page date pickers to remain unrestricted, so that I can generate reports for any historical or future date range.

#### Acceptance Criteria

1. THE `Report_Page` SHALL use `showDatePicker` directly without running month restrictions.
2. WHEN a user selects dates on the `Report_Page`, THE `Report_Page` SHALL allow any date from `DateTime(2020)` to `DateTime(2030)`.
3. THE `App_Date_Picker` utility SHALL NOT be used in `Report_Page`.

---

### Requirement 5: Centralized Date Picker Usage

**User Story:** As a developer, I want all non-report date pickers to use the centralized `App_Date_Picker` utility, so that running month restrictions are consistently enforced across the app.

#### Acceptance Criteria

1. THE `Meal_Page` SHALL use `App_Date_Picker.show` for all date selection operations.
2. THE `Expense_Entry_Page` SHALL use `App_Date_Picker.show` if a date picker is added for expense date selection.
3. THE `Deposit_Page` SHALL use `App_Date_Picker.show` if a date picker is added for deposit date selection.
4. THE `Withdraw_Request_Page` SHALL use `App_Date_Picker.show` if a date picker is added for withdrawal date selection.
5. WHEN `App_Date_Picker.show` is called, THE `App_Date_Picker` SHALL require a `messId` parameter to determine the running month range from `Active_Month_Service`.
6. WHERE a `Selected_Month_Context` is provided, THE `App_Date_Picker` SHALL accept an optional `overrideMonthKey` parameter to use instead of querying `Active_Month_Service`.

---

### Requirement 6: Month Close এর পর Running Month পরিবর্তন

**User Story:** As a mess manager, I want the running month to automatically update after I close the current month, so that all date pickers reflect the new running month immediately.

#### Acceptance Criteria

1. WHEN a manager performs Month_Close via `Mess_Settings_Page`, THE system SHALL create a document in `messes/{messId}/monthSummaries/{monthKey}`.
2. AFTER Month_Close is completed, WHEN `Active_Month_Service.getRunningMonthKey` is called, THE `Active_Month_Service` SHALL return the next month's key as the running month.
3. WHEN the running month changes after Month_Close, THE `App_Date_Picker` SHALL reflect the new running month range on the next invocation.
4. IF Month_Close has NOT been performed for the current calendar month, THEN THE `Active_Month_Service` SHALL continue to return the current calendar month as the running month, even if the calendar has advanced to the next month.

---

### Requirement 7: Date Navigation Arrows Restriction (Meal Page)

**User Story:** As a mess member, I want the previous/next day navigation arrows on the Meal page to be restricted to the running month, so that I cannot navigate to dates outside the running month.

#### Acceptance Criteria

1. WHEN a user taps the "previous day" arrow on the `Meal_Page`, THE `Meal_Page` SHALL only navigate to the previous day if it is within the running month range.
2. WHEN a user taps the "next day" arrow on the `Meal_Page`, THE `Meal_Page` SHALL only navigate to the next day if it is within the running month range.
3. WHILE the selected date is the first day of the running month, THE `Meal_Page` SHALL disable the "previous day" arrow.
4. WHILE the selected date is the last day of the running month, THE `Meal_Page` SHALL disable the "next day" arrow.
5. FOR ALL navigation operations on the `Meal_Page`, the resulting selected date SHALL satisfy: `firstDayOfRunningMonth <= selectedDate <= lastDayOfRunningMonth`.
