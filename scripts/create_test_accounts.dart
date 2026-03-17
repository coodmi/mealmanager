#!/usr/bin/env dart

// Run this script with: dart scripts/create_test_accounts.dart
// This script creates the 3 test accounts in Firebase

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    print('🚀 Starting test account creation...\n');

    await createTestAccounts();

    print('\n✅ All test accounts created successfully!');
    print('\n📋 TEST ACCOUNTS SUMMARY:\n');
    printTestAccounts();

    exit(0);
  } catch (e) {
    print('\n❌ Error: $e');
    exit(1);
  }
}

Future<void> createTestAccounts() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final accounts = [
    {
      'name': 'Super Admin',
      'email': 'superadmin@mealmanager.com',
      'password': 'SuperAdmin@123',
      'mobile': '+880-1700-000001',
      'role': 'super_admin',
    },
    {
      'name': 'Rahul Kumar',
      'email': 'user@mealmanager.com',
      'password': 'NormalUser@123',
      'mobile': '+880-1700-000002',
      'role': 'member',
    },
    {
      'name': 'Karim Ahmed',
      'email': 'messadmin@mealmanager.com',
      'password': 'MessAdmin@123',
      'mobile': '+880-1700-000003',
      'role': 'mess_admin',
    },
  ];

  for (final account in accounts) {
    try {
      print('Creating: ${account['name']}...');

      // Create user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: account['email'] as String,
        password: account['password'] as String,
      );

      final user = userCredential.user;
      if (user != null) {
        // Save to Firestore
        await firestore.collection('users').doc(user.uid).set({
          'name': account['name'],
          'email': account['email'],
          'mobile': account['mobile'],
          'role': account['role'],
          'messId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
          'isActive': true,
        });

        print('  ✓ ${account['email']} created successfully\n');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('  ⚠️  ${account['email']} already exists\n');
      } else {
        print('  ✗ Error: ${e.message}\n');
      }
    }
  }
}

void printTestAccounts() {
  final accounts = [
    {
      'role': 'Super Admin',
      'email': 'superadmin@mealmanager.com',
      'password': 'SuperAdmin@123',
      'phone': '+880-1700-000001',
    },
    {
      'role': 'Normal User',
      'email': 'user@mealmanager.com',
      'password': 'NormalUser@123',
      'phone': '+880-1700-000002',
    },
    {
      'role': 'Mess Admin',
      'email': 'messadmin@mealmanager.com',
      'password': 'MessAdmin@123',
      'phone': '+880-1700-000003',
    },
  ];

  for (final account in accounts) {
    print('Role:     ${account['role']}');
    print('Email:    ${account['email']}');
    print('Password: ${account['password']}');
    print('Phone:    ${account['phone']}');
    print('');
  }
}

void exit(int code) {
  throw SystemExit(code);
}

class SystemExit implements Exception {
  final int exitCode;
  SystemExit(this.exitCode);
}

