import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Register user with email and password
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Failed to create user'};
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'mobile': mobile,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'messId': null,
        'role': 'member',
      });

      // Send email verification
      await user.sendEmailVerification();

      return {
        'success': true,
        'message': 'Registration successful! Please verify your email.',
        'userId': user.uid,
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
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Login user — supports both email and mobile number
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      String loginEmail = email.trim();

      // If input looks like a mobile number (all digits, starts with 0 or +), look up email
      final isMobile = RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(loginEmail);
      if (isMobile) {
        final query = await _firestore
            .collection('users')
            .where('mobile', isEqualTo: loginEmail)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          return {'success': false, 'message': 'Wrong ID/Password entered'};
        }
        loginEmail = query.docs.first.data()['email'] as String? ?? loginEmail;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Wrong ID/Password entered'};
      }

      return {
        'success': true,
        'message': 'Login successful',
        'userId': user.uid,
      };
    } on FirebaseAuthException catch (e) {
      // Always show a simple message regardless of the actual error code
      switch (e.code) {
        case 'user-disabled':
          return {
            'success': false,
            'message': 'This account has been disabled',
          };
        default:
          return {'success': false, 'message': 'Wrong ID/Password entered'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Wrong ID/Password entered'};
    }
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in cancelled'};
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return {'success': false, 'message': 'Sign-in failed'};

      // Create Firestore doc if first time
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'mobile': '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'messId': null,
          'role': 'member',
        });
      }

      return {
        'success': true,
        'message': 'Login successful',
        'userId': user.uid,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Google sign-in failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in failed'};
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Update user data
  static Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return currentUser != null;
  }

  // Get user ID
  static String? getUserId() {
    return currentUser?.uid;
  }
}
