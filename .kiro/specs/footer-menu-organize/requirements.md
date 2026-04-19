# Requirements Document

## Introduction

This feature reorganizes the bottom navigation bar (footer menu) of the Flutter app to follow a new tab order: Menu | Transaction | Home | Chat | Profile. The current order (Meal | Member | Home | Transaction | Menu) is replaced with a new five-tab layout that promotes the Home tab to the center position, surfaces Chat and Profile as dedicated bottom nav tabs, and replaces the Meal and Member tabs with Menu and Transaction in the leftmost positions. The Profile tab moves from the app bar popup menu into the footer for easier access.

## Glossary

- **Bottom_Navigation_Bar**: The persistent footer widget rendered via `_buildBottomNav()` in `DashboardPage`, containing tappable tab items.
- **Dashboard_Page**: The root page (`DashboardPage`) that hosts the `Bottom_Navigation_Bar` and the `pages` list indexed by `_selectedIndex`.
- **Tab**: A single item in the `Bottom_Navigation_Bar`, consisting of an icon and a label.
- **Selected_Index**: The integer state variable `_selectedIndex` in `DashboardPage` that determines which page is currently displayed.
- **Home_Tab**: The center tab (index 2) displaying the home/dashboard content.
- **Menu_Tab**: The leftmost tab (index 0) displaying the mess settings / menu page.
- **Transaction_Tab**: The second tab (index 1) displaying the transaction page.
- **Chat_Tab**: The fourth tab (index 3) displaying the chat page.
- **Profile_Tab**: The rightmost tab (index 4) displaying the user profile page.
- **Deep_Link**: A programmatic navigation call that sets `_selectedIndex` to a specific tab by name.

---

## Requirements

### Requirement 1: Tab Order

**User Story:** As a user, I want the footer menu tabs to appear in the order Menu | Transaction | Home | Chat | Profile, so that I can navigate to the most important sections quickly and intuitively.

#### Acceptance Criteria

1. THE `Bottom_Navigation_Bar` SHALL display exactly five tabs in left-to-right order: Menu (index 0), Transaction (index 1), Home (index 2), Chat (index 3), Profile (index 4).
2. WHEN the app launches, THE `Dashboard_Page` SHALL display the Home tab content by default (`_selectedIndex` = 2).
3. THE `Bottom_Navigation_Bar` SHALL render the Menu tab at position 0 with an appropriate menu icon and the label "Menu".
4. THE `Bottom_Navigation_Bar` SHALL render the Transaction tab at position 1 with an appropriate transaction icon and the label "Transaction".
5. THE `Bottom_Navigation_Bar` SHALL render the Home tab at position 2 with an appropriate home icon and the label "Home".
6. THE `Bottom_Navigation_Bar` SHALL render the Chat tab at position 3 with an appropriate chat icon and the label "Chat".
7. THE `Bottom_Navigation_Bar` SHALL render the Profile tab at position 4 with an appropriate profile icon and the label "Profile".

---

### Requirement 2: Tab Navigation

**User Story:** As a user, I want tapping any footer tab to navigate me to the corresponding page, so that I can switch between sections without losing context.

#### Acceptance Criteria

1. WHEN the user taps the Menu tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 0 and display the Menu page.
2. WHEN the user taps the Transaction tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 1 and display the Transaction page.
3. WHEN the user taps the Home tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 2 and display the Home page.
4. WHEN the user taps the Chat tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 3 and display the Chat page.
5. WHEN the user taps the Profile tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 4 and display the Profile page.
6. WHEN a tab is selected, THE `Bottom_Navigation_Bar` SHALL highlight the active tab using the existing selected visual style (green tint background and green icon/label color).
7. WHEN a tab is not selected, THE `Bottom_Navigation_Bar` SHALL render the tab in the existing unselected visual style (transparent background and grey icon/label color).

---

### Requirement 3: Pages List Alignment

**User Story:** As a developer, I want the `pages` list in `DashboardPage` to be aligned with the new tab indices, so that each tab renders the correct page content.

#### Acceptance Criteria

1. THE `Dashboard_Page` SHALL define the `pages` list with five entries ordered as: `[MenuPage, TransactionPage, HomePage, ChatPage, ProfilePage]` corresponding to indices 0–4.
2. THE `Dashboard_Page` SHALL remove the Meal page (previously index 0) and Member page (previously index 1) from the `pages` list used by the `Bottom_Navigation_Bar`.
3. WHEN `_selectedIndex` is 0, THE `Dashboard_Page` SHALL render `MenuPage`.
4. WHEN `_selectedIndex` is 1, THE `Dashboard_Page` SHALL render `TransactionPage`.
5. WHEN `_selectedIndex` is 2, THE `Dashboard_Page` SHALL render the home content widget.
6. WHEN `_selectedIndex` is 3, THE `Dashboard_Page` SHALL render `ChatPage`.
7. WHEN `_selectedIndex` is 4, THE `Dashboard_Page` SHALL render `ProfilePage`.

---

### Requirement 4: Deep Link Index Consistency

**User Story:** As a developer, I want all programmatic navigation calls that set `_selectedIndex` by tab name to use the updated index values, so that deep links and internal navigation remain correct after the reorder.

#### Acceptance Criteria

1. WHEN a deep link or internal call targets the "Menu" tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 0.
2. WHEN a deep link or internal call targets the "Transaction" tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 1.
3. WHEN a deep link or internal call targets the "Home" tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 2.
4. WHEN a deep link or internal call targets the "Chat" tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 3.
5. WHEN a deep link or internal call targets the "Profile" tab, THE `Dashboard_Page` SHALL set `_selectedIndex` to 4.
6. THE `Dashboard_Page` SHALL remove or update any hardcoded index references that correspond to the old tab order (Meal = 0, Member = 1, Transaction = 3, Menu = 4).

---

### Requirement 5: Profile Tab Promotion

**User Story:** As a user, I want to access my profile directly from the footer menu, so that I no longer need to open the app bar popup to reach the profile page.

#### Acceptance Criteria

1. THE `Bottom_Navigation_Bar` SHALL include a Profile tab as a first-class navigation item at index 4.
2. WHEN the user taps the Profile tab, THE `Dashboard_Page` SHALL navigate to the Profile page inline (within the `pages` list), replacing the current popup-menu-based navigation.
3. WHERE the Profile option previously existed only in the app bar popup menu, THE `Dashboard_Page` SHALL retain or remove the popup entry based on UX preference, but the footer Profile tab SHALL always be present and functional.

---

### Requirement 6: Chat Tab Introduction

**User Story:** As a user, I want a dedicated Chat tab in the footer menu, so that I can access the chat feature with a single tap.

#### Acceptance Criteria

1. THE `Bottom_Navigation_Bar` SHALL include a Chat tab at index 3.
2. WHEN the user taps the Chat tab, THE `Dashboard_Page` SHALL display the Chat page at index 3 of the `pages` list.
3. IF the Chat page widget does not yet exist, THEN THE `Dashboard_Page` SHALL display a placeholder widget with the label "Chat" until the full Chat page is implemented.
