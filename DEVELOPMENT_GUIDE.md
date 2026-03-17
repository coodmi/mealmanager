# Meal Manager - Development Guide

## Project Setup Complete ✅

### What's Been Built:
1. **Core Architecture**
   - Theme system with brand colors (Green: #177C60, #11835B, Red: #AF1F23)
   - App constants and strings
   - Navigation routing with go_router

2. **Screens Implemented**
   - ✅ Login/Register Page (with tabs)
   - ✅ OTP Verification Page
   - ✅ Create/Join Mess Page
   - ✅ Dashboard Page (with balance, overview, quick actions)

3. **Dependencies Added**
   - State management: provider
   - Navigation: go_router
   - Local storage: shared_preferences, sqflite
   - Network: http
   - UI: google_fonts, flutter_svg
   - Utils: intl, uuid

## Next Steps to Run:

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. For Web
```bash
flutter run -d chrome
```

## Remaining Screens to Build:

### High Priority:
- [ ] Mess Settings Page
- [ ] Members List Page
- [ ] Meal Entry Page
- [ ] Expense Entry Page
- [ ] Withdraw Page
- [ ] Reports Page
- [ ] Profile Page

### Medium Priority:
- [ ] Subscription System
- [ ] Menu Screens (User Guide, Suggestion Box, etc.)
- [ ] Chat Feature
- [ ] Notifications System

### Backend/Advanced:
- [ ] Super Admin Panel
- [ ] API Integration
- [ ] Offline Sync Engine
- [ ] Payment Gateway Integration
- [ ] PDF Generation

## Project Structure:
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── router/
│       └── app_router.dart
├── features/
│   ├── auth/
│   │   └── presentation/pages/
│   ├── mess/
│   │   └── presentation/pages/
│   └── dashboard/
│       └── presentation/pages/
└── main.dart
```

## Key Features to Implement:

### 1. State Management
- Add Provider/Riverpod for state
- Create models for User, Mess, Meal, Expense
- Implement local database with sqflite

### 2. Backend Integration
- Setup API endpoints
- Implement authentication
- Real-time sync logic

### 3. Offline Support
- Local database caching
- Sync queue management
- Conflict resolution

### 4. Notifications
- Firebase Cloud Messaging
- Local notifications
- In-app notification center

## Design Guidelines:
- Primary Green: #177C60
- Button Green: #11835B
- Dark Red: #AF1F23
- Background: #F9FFF7
- Card White: #FFFFFF

## Testing:
```bash
flutter test
```

## Build for Production:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Notes:
- Logo files should be placed in `assets/images/`
- Icons should be placed in `assets/icons/`
- Email: MealManagerApps@gmail.com
- Mess ID format: MM1000+

## Contact:
For questions or issues, refer to the original specification document.
