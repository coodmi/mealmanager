# Implementation Guide: Test Accounts

## 🎯 Quick Start (5 minutes)

### Step 1: Import the Class
```dart
import 'package:mealmanager/core/services/test_account_creator.dart';
```

### Step 2: Create Accounts
```dart
// Call this once to create all 3 test accounts
final results = await TestAccountCreator.createAllTestAccounts();

// Print to console
TestAccountCreator.printTestAccounts();
```

### Step 3: Use the Credentials
```
Super Admin:     superadmin@mealmanager.com / SuperAdmin@123
Normal User:     user@mealmanager.com / NormalUser@123
Mess Admin:      messadmin@mealmanager.com / MessAdmin@123
```

---

## 📱 Advanced Usage

### Create Single Account
```dart
final result = await TestAccountCreator.createTestAccount(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'Password@123',
  mobile: '+880-1700-000000',
  role: 'member',
);

if (result['success']) {
  print('Account created: ${result['userId']}');
} else {
  print('Error: ${result['message']}');
}
```

### Get All Test Accounts
```dart
final accounts = TestAccountCreator.getAllTestAccounts();
for (final account in accounts) {
  print('${account['name']}: ${account['email']}');
}
```

### Delete Test Account
```dart
final deleted = await TestAccountCreator.deleteTestAccount(
  'superadmin@mealmanager.com'
);

if (deleted) {
  print('Account deleted');
} else {
  print('Account not found');
}
```

---

## 🖥️ UI Integration

### Add Debug Page to Navigation
```dart
// In your app router or navigation
GoRoute(
  path: '/debug/test-accounts',
  builder: (context, state) => const DebugTestAccountPage(),
),
```

### Add Button to Drawer
```dart
ListTile(
  title: const Text('Create Test Accounts'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugTestAccountPage(),
      ),
    );
  },
),
```

---

## 🔧 Configuration

### Custom Test Accounts
Edit `test_account_creator.dart` and modify:

```dart
static const Map<String, Map<String, String>> testAccounts = {
  'superadmin': {
    'email': 'superadmin@mealmanager.com',
    'password': 'SuperAdmin@123',
    'name': 'Super Admin',
    'mobile': '+880-1700-000001',
    'role': 'super_admin',
  },
  // Add more accounts here...
};
```

---

## 📊 Firestore Structure

After account creation, user documents will look like:

```json
{
  "users": {
    "uid_1": {
      "name": "Super Admin",
      "email": "superadmin@mealmanager.com",
      "mobile": "+880-1700-000001",
      "role": "super_admin",
      "messId": null,
      "createdAt": "2026-03-01T10:00:00Z",
      "isEmailVerified": false,
      "isActive": true
    }
  }
}
```

---

## 🧪 Testing Scenarios

### Scenario 1: Role-Based Access
```dart
// Login as Super Admin
// Verify: Can see all admin features

// Login as Normal User
// Verify: Limited to user features

// Login as Mess Admin
// Verify: Can manage mess features
```

### Scenario 2: Profile Management
```dart
// Login with any account
// Click Account → Edit Profile
// Verify:
// - Name field updates
// - Phone number updates
// - Email is read-only
```

### Scenario 3: Responsive Design
```dart
// Login with any account
// Test on different screen sizes:
// - Mobile (360px)
// - Tablet (600px)
// - Desktop (1200px)
// Verify: All dialogs fit the screen
```

---

## ⚙️ Database Queries

### Query by Role
```dart
final query = FirebaseFirestore.instance
    .collection('users')
    .where('role', isEqualTo: 'super_admin')
    .get();
```

### Query by Email
```dart
final query = FirebaseFirestore.instance
    .collection('users')
    .where('email', isEqualTo: 'superadmin@mealmanager.com')
    .get();
```

### Get Current User Role
```dart
final currentUser = FirebaseAuth.instance.currentUser;
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUser!.uid)
    .get();

final role = userDoc.get('role');
```

---

## 🔒 Security Considerations

### For Development Only
- Test accounts are meant for development
- Never use in production
- Delete before deploying to production

### Password Policy
- Minimum 8 characters
- 1 uppercase letter
- 1 lowercase letter
- 1 number
- 1 special character

### Email Verification
- Test emails don't require verification
- Can be any valid email format
- No actual email will be sent

---

## 🐛 Debugging

### Print Account Info
```dart
TestAccountCreator.printTestAccounts();

// Output:
// ========== TEST ACCOUNTS ==========
// Account 1: SUPER ADMIN
//   Email: superadmin@mealmanager.com
//   Password: SuperAdmin@123
//   Phone: +880-1700-000001
//   Role: super_admin
// ...
```

### Check Firestore
```dart
// In Firebase Console:
// 1. Go to Firestore Database
// 2. Navigate to users collection
// 3. Should see 3 documents (one per account)
// 4. Verify 'role' field is set correctly
```

### Check Firebase Auth
```dart
// In Firebase Console:
// 1. Go to Authentication → Users
// 2. Should see 3 users with the test emails
// 3. Click each to verify email addresses
```

---

## 🚀 Production Checklist

Before deploying:

- [ ] Remove/comment out test account code
- [ ] Delete all test accounts from Firebase
- [ ] Remove debug pages from navigation
- [ ] Hide test account UI elements
- [ ] Verify authentication works with real users
- [ ] Test role-based access with real data

---

## 📚 Related Files

- `lib/core/services/test_account_creator.dart` - Account creator class
- `lib/features/debug/presentation/pages/debug_test_account_page.dart` - Debug UI
- `lib/core/services/firebase_auth_service.dart` - Auth service
- `scripts/create_test_accounts.dart` - CLI script

---

## 💬 Support

For issues or questions:
1. Check the error message in console
2. Verify Firebase credentials
3. Check Firestore rules
4. Review Firebase Auth documentation
5. See troubleshooting section in TEST_ACCOUNTS.md

---

**Happy Testing! 🎉**

