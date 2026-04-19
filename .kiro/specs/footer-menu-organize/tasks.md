# Implementation Plan: Footer Menu Organize

## Overview

Reorganize `DashboardPage` bottom navigation from the old layout (Meal | Member | Home | Transaction | Menu) to the new layout (Menu | Transaction | Home | Chat | Profile) by updating the `pages` list, `_buildBottomNav()`, and `_onActionTap()` index references.

## Tasks

- [x] 1. Update the `pages` list in `DashboardPage`
  - In `lib/features/dashboard/presentation/pages/dashboard_page.dart`, replace the five-entry `pages` list with: `[MenuPage, TransactionPage, _buildHomePage(), ChatPage, ProfilePage]`
  - Remove `MealPageWorking` (old index 0) and `MemberPage` (old index 1) from the list
  - Ensure required imports for `ChatPage` and `ProfilePage` are present
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 2. Update `_buildBottomNav()` nav items
  - [x] 2.1 Replace the five nav items with the new order and icons
    - Index 0: `Icons.grid_view_rounded`, label `"Menu"`
    - Index 1: `Icons.receipt_long`, label `"Transaction"`
    - Index 2: `Icons.home_rounded`, label `"Home"`
    - Index 3: `Icons.chat_bubble_outline_rounded`, label `"Chat"`
    - Index 4: `Icons.person_outline_rounded`, label `"Profile"`
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 2.2 Write widget test for tab order
    - Pump `DashboardPage`, find the bottom nav row, assert labels appear in order: `['Menu', 'Transaction', 'Home', 'Chat', 'Profile']`
    - _Requirements: 1.1_

- [x] 3. Fix `_onActionTap()` index references
  - Update the `'Menu'` case to set `_selectedIndex = 0` (was 4)
  - Update the `'Transaction'` case to set `_selectedIndex = 1` (was 3)
  - Remove or no-op the `'Members'` and `'Meal'` cases (no longer footer tabs)
  - _Requirements: 4.1, 4.2, 4.6_

- [x] 4. Verify default selected index and initial state
  - Confirm `_selectedIndex` initializes to `2` (Home) — no change needed if already correct
  - _Requirements: 1.2_

  - [ ]* 4.1 Write widget test for default index
    - Pump `DashboardPage`, assert home content widget is visible and `_selectedIndex == 2`
    - _Requirements: 1.2_

- [ ] 5. Checkpoint — Ensure all tests pass
  - Run `flutter test` and confirm no regressions. Ask the user if questions arise.

- [ ] 6. Write property-based and navigation tests
  - [ ]* 6.1 Write property test for tap navigation (Property 1)
    - **Property 1: Tap navigation sets correct index and page**
    - Generator: integer in `[0, 4]`; tap nav item at that index; assert `_selectedIndex == i` and `pages[i]` widget type matches expected
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 3.3, 3.4, 3.5, 3.6, 3.7**

  - [ ]* 6.2 Write property test for selected tab styling exclusivity (Property 2)
    - **Property 2: Selected tab styling is exclusive**
    - Generator: integer in `[0, 4]`; set `_selectedIndex`; assert selected item has green tint, all others have transparent/grey style
    - **Validates: Requirements 2.6, 2.7**

  - [ ]* 6.3 Write property test for programmatic navigation by tab name (Property 3)
    - **Property 3: Deep link / programmatic navigation maps tab names to correct indices**
    - Generator: element from `[('Menu',0), ('Transaction',1), ('Home',2), ('Chat',3), ('Profile',4)]`; invoke navigation with tab name; assert `_selectedIndex == expectedIndex`
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**

  - [ ]* 6.4 Write widget test for Quick Actions index correctness
    - Tap 'Menu' quick action, assert `_selectedIndex == 0`; tap 'Transaction' quick action, assert `_selectedIndex == 1`
    - _Requirements: 4.1, 4.2_

- [ ] 7. Final checkpoint — Ensure all tests pass
  - Run `flutter test` and confirm the full suite is green. Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- All changes are confined to `dashboard_page.dart` — no other files require modification
- `ChatPage` and `ProfilePage` already exist; no new page widgets need to be created
- Property tests use the [`fast_check`](https://pub.dev/packages/fast_check) Dart PBT library (minimum 100 iterations each)
