import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestAccountCreator {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test account credentials
  static const Map<String, Map<String, String>> testAccounts = {
    'superadmin': {
      'email': 'superadmin@mealmanager.com',
      'password': 'SuperAdmin@123',
      'name': 'Super Admin',
      'mobile': '+880-1700-000001',
      'role': 'super_admin',
    },
    'user': {
      'email': 'user@mealmanager.com',
      'password': 'NormalUser@123',
      'name': 'Rahul Kumar',
      'mobile': '+880-1700-000002',
      'role': 'member',
    },
    'messadmin': {
      'email': 'messadmin@mealmanager.com',
      'password': 'MessAdmin@123',
      'name': 'Karim Ahmed',
      'mobile': '+880-1700-000003',
      'role': 'mess_admin',
    },
  };

  /// Create all test accounts
  static Future<Map<String, dynamic>> createAllTestAccounts() async {
    final results = <String, dynamic>{};

    for (final entry in testAccounts.entries) {
      final accountType = entry.key;
      final credentials = entry.value;

      try {
        final result = await createTestAccount(
          name: credentials['name']!,
          email: credentials['email']!,
          password: credentials['password']!,
          mobile: credentials['mobile']!,
          role: credentials['role']!,
        );

        if (result['success']) {
          results[accountType] = {
            'status': 'created',
            'email': credentials['email'],
            'password': credentials['password'],
            'userId': result['userId'],
          };
        } else {
          results[accountType] = {
            'status': 'error',
            'message': result['message'],
          };
        }
      } catch (e) {
        results[accountType] = {
          'status': 'error',
          'message': e.toString(),
        };
      }
    }

    return results;
  }

  /// Create a single test account
  static Future<Map<String, dynamic>> createTestAccount({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String role,
  }) async {
    try {
      // Check if account already exists
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return {
          'success': false,
          'message': 'Account already exists',
        };
      } catch (e) {
        if (e is FirebaseAuthException && e.code != 'user-not-found') {
          rethrow;
        }
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to create user',
        };
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'mobile': mobile,
        'role': role,
        'messId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'isActive': true,
      });

      return {
        'success': true,
        'message': 'Account created successfully',
        'userId': user.uid,
        'email': email,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Delete a test account (useful for cleanup)
  static Future<bool> deleteTestAccount(String email) async {
    try {
      final user = _auth.currentUser;
      if (user?.email == email) {
        await user!.delete();
        return true;
      }

      // Try to find and delete by querying Firestore
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(query.docs.first.id)
            .delete();
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  /// Get all test account credentials (for reference)
  static List<Map<String, String>> getAllTestAccounts() {
    return testAccounts.values.toList();
  }

  /// Print test accounts in a formatted way
  static void printTestAccounts() {
    print('\n========== TEST ACCOUNTS ==========');
    print('Account 1: SUPER ADMIN');
    print('  Email: ${testAccounts['superadmin']!['email']}');
    print('  Password: ${testAccounts['superadmin']!['password']}');
    print('  Phone: ${testAccounts['superadmin']!['mobile']}');
    print('  Role: ${testAccounts['superadmin']!['role']}');

    print('\nAccount 2: NORMAL USER');
    print('  Email: ${testAccounts['user']!['email']}');
    print('  Password: ${testAccounts['user']!['password']}');
    print('  Phone: ${testAccounts['user']!['mobile']}');
    print('  Role: ${testAccounts['user']!['role']}');

    print('\nAccount 3: MESS ADMIN');
    print('  Email: ${testAccounts['messadmin']!['email']}');
    print('  Password: ${testAccounts['messadmin']!['password']}');
    print('  Phone: ${testAccounts['messadmin']!['mobile']}');
    print('  Role: ${testAccounts['messadmin']!['role']}');

    print('====================================\n');
  }
}

