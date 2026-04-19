# Implementation Plan: Date Selection Running Month Restriction

## Overview

`ActiveMonthService` ও `AppDatePicker` আপডেট করে রানিং মাস-ভিত্তিক ডেট রেস্ট্রিকশন enforce করা হবে। `DashboardPage` থেকে `selectedMonthKey` context child pages-এ pass করা হবে এবং `MealPageWorking`-এ navigation arrow restriction যোগ করা হবে।

## Tasks

- [x] 1. ActiveMonthService পরিমার্জন
  - `lib/core/services/active_month_service.dart`-এ `DateTimeRange` import `package:flutter/material.dart` থেকে নিশ্চিত করা
  - `getRunningMonthKey(messId)` — Firestore doc না থাকলে current month, থাকলে next month return করে কিনা যাচাই করা
  - `getRunningMonthRange(messId)` — `DateTimeRange(start: firstDay, end: lastDay)` সঠিকভাবে return করে কিনা যাচাই করা
  - Firestore query fail হলে current calendar month fallback নিশ্চিত করা
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. AppDatePicker আপডেট
  - [x] 2.1 `overrideMonthKey` optional parameter যোগ করা
    - `lib/core/utils/app_date_picker.dart`-এ `show()` method-এ `String? overrideMonthKey` parameter যোগ করা
    - `overrideMonthKey != null` হলে `ActiveMonthService` query না করে সেই month-এর range compute করা
    - `overrideMonthKey == null` হলে `ActiveMonthService.getRunningMonthRange(messId)` call করা
    - `initialDate` clamping: `max(firstDay, min(lastDay, initialDate ?? DateTime.now()))`
    - _Requirements: 3.1, 3.4, 5.5, 5.6_

  - [ ]* 2.2 Property test: overrideMonthKey takes precedence (Property 5)
    - **Property 5: Override Month Key Takes Precedence**
    - **Validates: Requirements 2.2, 5.6**
    - `overrideMonthKey` দেওয়া হলে `firstDate`/`lastDate` সেই month-এর হয়, service result নয়

  - [ ]* 2.3 Property test: initialDate clamping (Property 4)
    - **Property 4: InitialDate Clamping**
    - **Validates: Requirements 3.4**
    - Running month-এর বাইরের যেকোনো `initialDate` clamp হয়ে range-এর মধ্যে আসে

- [ ] 3. ActiveMonthService property tests
  - [ ]* 3.1 Property test: no close → current month (Property 1)
    - **Property 1: No Month Close → Current Month is Running Month**
    - **Validates: Requirements 1.1, 6.4**
    - Mock Firestore: doc নেই → `getRunningMonthKey` current month key return করে

  - [ ]* 3.2 Property test: close → next month (Property 2)
    - **Property 2: Month Close → Next Month is Running Month**
    - **Validates: Requirements 1.2, 6.2**
    - Mock Firestore: doc আছে → `getRunningMonthKey` next month key return করে

  - [ ]* 3.3 Property test: range boundaries (Property 3)
    - **Property 3: Running Month Range Boundaries**
    - **Validates: Requirements 1.3, 3.1**
    - যেকোনো valid month key-এর জন্য `range.start.day == 1` এবং `range.end` সেই মাসের শেষ দিন

- [x] 4. Checkpoint — ActiveMonthService ও AppDatePicker tests pass করা
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. DashboardPage-এ selectedMonthKey context যোগ করা
  - `lib/features/dashboard/presentation/pages/dashboard_page.dart`-এ `String? _selectedMonthKey` state যোগ করা
  - Top bar-এ month switch করলে `_selectedMonthKey` update হবে
  - `_selectedMonthKey` child pages (`MealPageWorking`, `ExpenseEntryPage`, `DepositPage`, `WithdrawRequestPage`)-এ constructor parameter হিসেবে pass করা
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 6. MealPageWorking আপডেট
  - [x] 6.1 `selectedMonthKey` constructor parameter যোগ করা
    - `lib/features/meal/presentation/pages/meal_page_working.dart`-এ `final String? selectedMonthKey` parameter যোগ করা
    - `AppDatePicker.show` call-এ `overrideMonthKey: widget.selectedMonthKey` pass করা
    - _Requirements: 2.2, 5.1_

  - [x] 6.2 Navigation arrow restriction implement করা
    - Running month range নির্ধারণ করতে `selectedMonthKey` বা `ActiveMonthService` ব্যবহার করা
    - `_selectedDate == firstDayOfRunningMonth` হলে previous arrow disable করা
    - `_selectedDate == lastDayOfRunningMonth` হলে next arrow disable করা
    - Arrow tap-এ boundary check করে navigate করা
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 6.3 Property test: day navigation stays within running month (Property 7)
    - **Property 7: Day Navigation Stays Within Running Month**
    - **Validates: Requirements 7.1, 7.2, 7.5**
    - যেকোনো prev/next navigation sequence-এ `_selectedDate` সবসময় `[firstDay, lastDay]`-এর মধ্যে থাকে

- [x] 7. ExpenseEntryPage, DepositPage, WithdrawRequestPage-এ selectedMonthKey parameter যোগ করা
  - তিনটি page-এ `final String? selectedMonthKey` constructor parameter যোগ করা
  - ভবিষ্যতে date picker যোগ হলে `AppDatePicker.show(overrideMonthKey: widget.selectedMonthKey)` ব্যবহারের জন্য প্রস্তুত রাখা
  - _Requirements: 2.4, 5.2, 5.3, 5.4_

- [x] 8. ReportsPdfPage অপরিবর্তিত যাচাই করা
  - `lib/features/reports/presentation/pages/reports_pdf_page.dart` সরাসরি `showDatePicker` ব্যবহার করে কিনা নিশ্চিত করা
  - `firstDate: DateTime(2020)`, `lastDate: DateTime(2030)` range অপরিবর্তিত আছে কিনা যাচাই করা
  - `AppDatePicker` ব্যবহার করা হচ্ছে না কিনা নিশ্চিত করা
  - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 8.1 Unit test: report page unrestricted date range
    - Report page `showDatePicker`-এ `firstDate: DateTime(2020)` ও `lastDate: DateTime(2030)` pass করে কিনা verify করা
    - _Requirements: 4.1, 4.2_

- [x] 9. Final Checkpoint — সব tests pass করা
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- `*` চিহ্নিত sub-tasks optional — MVP-র জন্য skip করা যাবে
- প্রতিটি property test-এ comment tag থাকবে: `// Feature: date-selection-running-month-restriction, Property N: <property_text>`
- Property tests minimum 100 iterations চালাবে
- `ActiveMonthService` বিদ্যমান implementation সঠিক, শুধু import ও edge case নিশ্চিত করতে হবে
