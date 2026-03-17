# Test Accounts - Meal Manager

## 📋 Account Overview

Three test accounts have been created for development and testing purposes:

### 1. **Super Admin** 👨‍💼
- **Email**: `superadmin@mealmanager.com`
- **Password**: `SuperAdmin@123`
- **Name**: Super Admin
- **Phone**: +880-1700-000001
- **Role**: `super_admin`
- **Permissions**: 
  - Full access to all features
  - Can create/manage multiple mess systems
  - Can manage all users and admins
  - View complete analytics and reports

### 2. **Normal User** 👤
- **Email**: `user@mealmanager.com`
- **Password**: `NormalUser@123`
- **Name**: Rahul Kumar
- **Phone**: +880-1700-000002
- **Role**: `member`
- **Permissions**:
  - Can join/create mess
  - Manage own profile
  - View balance and transactions
  - Submit bills and track expenses

### 3. **Mess Admin** 🏠
- **Email**: `messadmin@mealmanager.com`
- **Password**: `MessAdmin@123`
- **Name**: Karim Ahmed
- **Phone**: +880-1700-000003
- **Role**: `mess_admin`
- **Permissions**:
  - Manage mess members
  - Approve/reject transactions
  - View mess reports
  - Manage meal schedules

---

## 🚀 How to Create Test Accounts

### Method 1: Using Debug Page (Easiest)

1. Navigate to the debug test account page
2. Click "Create Test Accounts" button
3. Wait for all accounts to be created
4. Credentials will be displayed on screen

### Method 2: Using Code

```dart
import 'package:mealmanager/core/services/test_account_creator.dart';

// Create all test accounts
final results = await TestAccountCreator.createAllTestAccounts();

// Create a single account
final result = await TestAccountCreator.createTestAccount(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'SecurePassword@123',
  mobile: '+880-1700-000000',
  role: 'member',
);
```

### Method 3: Using Firebase Console

1. Go to Firebase Console
2. Select your project
3. Authentication → Users
4. Click "Add User"
5. Enter email and password
6. Update Firestore user document with role

---

## 🔐 Password Requirements

All passwords follow security best practices:
- **Minimum Length**: 8 characters
- **Uppercase**: At least 1 (A-Z)
- **Lowercase**: At least 1 (a-z)
- **Numbers**: At least 1 (0-9)
- **Special Characters**: At least 1 (!@#$%^&*)

**Example**: `SuperAdmin@123`
- ✓ Uppercase: S
- ✓ Lowercase: uper, dmin
- ✓ Numbers: 123
- ✓ Special Character: @

---

## 📱 Testing Workflow

### 1. Login Tests
```
Test Case 1: Login with Super Admin
- Email: superadmin@mealmanager.com
- Password: SuperAdmin@123
- Expected: Access to admin dashboard

Test Case 2: Login with Normal User
- Email: user@mealmanager.com
- Password: NormalUser@123
- Expected: Access to user dashboard

Test Case 3: Login with Mess Admin
- Email: messadmin@mealmanager.com
- Password: MessAdmin@123
- Expected: Access to mess management features
```

### 2. Profile Tests
```
After login, click "Account" → "Edit Profile"
- Verify user data is loaded
- Test updating phone number
- Test changing password
- Verify responsive design on different screens
```

### 3. Mess Management Tests
```
Super Admin:
- Create new mess system
- Assign roles to users
- View all mess data

Mess Admin:
- Manage members in mess
- Approve transactions
- Set meal schedules

Normal User:
- Join/leave mess
- View balance
- Track expenses
```

---

## 🛠️ Troubleshooting

### Account Already Exists
If you see "Account already exists" error:
1. Delete the account from Firebase Console
2. Or use different email addresses
3. Try again with the creation button

### Password Doesn't Meet Requirements
Ensure password has:
- At least 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

### Can't Login After Creation
1. Check email and password spelling
2. Ensure user document exists in Firestore
3. Verify user is in "users" collection
4. Check user role is set correctly

---

## 📊 Database Structure

### Users Collection
```
/users/{uid}
├── name: "Super Admin"
├── email: "superadmin@mealmanager.com"
├── mobile: "+880-1700-000001"
├── role: "super_admin"  // super_admin, mess_admin, member
├── messId: null
├── createdAt: timestamp
├── isEmailVerified: false
└── isActive: true
```

### Test Account IDs (After Creation)
Will be displayed in the app after creation. Save these for reference.

---

## 🔄 Reset/Delete Test Accounts

To delete a test account:

```dart
// Delete by email
await TestAccountCreator.deleteTestAccount('superadmin@mealmanager.com');
```

Or manually in Firebase Console:
1. Go to Authentication → Users
2. Select the user
3. Click delete icon
4. Also delete the user document from Firestore

---

## ✅ Verification Checklist

After creating test accounts, verify:

- [ ] All 3 accounts created successfully
- [ ] Can login with each account
- [ ] User data loads in profile page
- [ ] Each account has correct role
- [ ] Responsive design works on mobile
- [ ] All dialogs are responsive
- [ ] Password change works
- [ ] Phone number update works

---

## 📝 Notes

- These are test accounts only - not for production
- Passwords should be changed before production deployment
- Emails don't need to be real (no verification required for testing)
- Phone numbers are formatted for Bangladesh region
- Modify test data as needed for your testing scenarios
- Keep this document for reference during development

---

## 🆘 Support

If you encounter issues:
1. Check the console for error messages
2. Verify Firebase credentials are correct
3. Ensure Firestore rules allow user creation
4. Check network connectivity
5. Review the code in `test_account_creator.dart`


