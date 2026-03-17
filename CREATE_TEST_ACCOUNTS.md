# Test Accounts for Meal Manager

## Account 1: Super Admin
- **Name**: Super Admin
- **Email**: superadmin@mealmanager.com
- **Password**: SuperAdmin@123
- **Phone**: +880-1700-000001
- **Role**: super_admin
- **Permissions**: Full access to all features and admin controls

## Account 2: Normal User
- **Name**: Rahul Kumar
- **Email**: user@mealmanager.com
- **Password**: NormalUser@123
- **Phone**: +880-1700-000002
- **Role**: member
- **Permissions**: Can join/create mess, manage own profile, view balance

## Account 3: Mess Admin
- **Name**: Karim Ahmed
- **Email**: messadmin@mealmanager.com
- **Password**: MessAdmin@123
- **Phone**: +880-1700-000003
- **Role**: mess_admin
- **Permissions**: Can manage mess members, transactions, and settings

---

## How to Create These Accounts

### Option 1: Using Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Meal Manager project
3. Go to Authentication → Users
4. Click "Add User" and enter the credentials above
5. After creating, update Firestore with the role

### Option 2: Using the Script Below

Run this script in your Flutter app (add to main.dart temporarily):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createTestAccounts() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Account 1: Super Admin
  try {
    final superAdmin = await auth.createUserWithEmailAndPassword(
      email: 'superadmin@mealmanager.com',
      password: 'SuperAdmin@123',
    );
    
    await firestore.collection('users').doc(superAdmin.user!.uid).set({
      'name': 'Super Admin',
      'email': 'superadmin@mealmanager.com',
      'mobile': '+880-1700-000001',
      'role': 'super_admin',
      'messId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✓ Super Admin created');
  } catch (e) {
    print('✗ Super Admin error: $e');
  }

  // Account 2: Normal User
  try {
    final normalUser = await auth.createUserWithEmailAndPassword(
      email: 'user@mealmanager.com',
      password: 'NormalUser@123',
    );
    
    await firestore.collection('users').doc(normalUser.user!.uid).set({
      'name': 'Rahul Kumar',
      'email': 'user@mealmanager.com',
      'mobile': '+880-1700-000002',
      'role': 'member',
      'messId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✓ Normal User created');
  } catch (e) {
    print('✗ Normal User error: $e');
  }

  // Account 3: Mess Admin
  try {
    final messAdmin = await auth.createUserWithEmailAndPassword(
      email: 'messadmin@mealmanager.com',
      password: 'MessAdmin@123',
    );
    
    await firestore.collection('users').doc(messAdmin.user!.uid).set({
      'name': 'Karim Ahmed',
      'email': 'messadmin@mealmanager.com',
      'mobile': '+880-1700-000003',
      'role': 'mess_admin',
      'messId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✓ Mess Admin created');
  } catch (e) {
    print('✗ Mess Admin error: $e');
  }
}
```

---

## Test Account Credentials Summary

| Role | Email | Password | Phone |
|------|-------|----------|-------|
| Super Admin | superadmin@mealmanager.com | SuperAdmin@123 | +880-1700-000001 |
| Normal User | user@mealmanager.com | NormalUser@123 | +880-1700-000002 |
| Mess Admin | messadmin@mealmanager.com | MessAdmin@123 | +880-1700-000003 |

---

## Notes
- All passwords follow strong password requirements (uppercase, lowercase, numbers, special characters)
- Phone numbers are formatted for Bangladesh
- Roles determine user permissions in the app
- These are test accounts and should not be used in production

