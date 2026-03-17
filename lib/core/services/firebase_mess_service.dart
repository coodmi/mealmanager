import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'firebase_auth_service.dart';

class FirebaseMessService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate Mess ID (MM1000+)
  static String generateMessId() {
    final random = Random();
    final number = 1000 + random.nextInt(99000);
    return 'MM$number';
  }

  // Create new mess
  static Future<Map<String, dynamic>> createMess({
    required String messName,
    required String address,
    required String district,
  }) async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final messId = generateMessId();

      // Create mess document
      await _firestore.collection('messes').doc(messId).set({
        'name': messName,
        'address': address,
        'district': district,
        'managerId': userId,
        'members': [userId],
        'balance': 0,
        'subscription': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user's messId
      await FirebaseAuthService.updateUserData({
        'messId': messId,
        'role': 'manager',
      });

      return {
        'success': true,
        'messId': messId,
        'message': 'Mess created successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create mess: $e'};
    }
  }

  // Join existing mess — creates a pending request
  static Future<Map<String, dynamic>> joinMess({required String messId}) async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Check if mess exists
      final messDoc = await _firestore.collection('messes').doc(messId).get();
      if (!messDoc.exists) {
        return {
          'success': false,
          'message': 'Mess not found. Check the ID and try again.',
        };
      }

      // Get user data for the request
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final name = userData['name'] as String? ?? 'Unknown';
      final phone = userData['phone'] as String? ?? '';
      final email = userData['email'] as String? ?? '';

      // Create a join request (pending)
      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('joinRequests')
          .doc(userId)
          .set({
            'userId': userId,
            'name': name,
            'phone': phone,
            'email': email,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          });

      // Update user's messId and status as pending
      await FirebaseAuthService.updateUserData({
        'messId': messId,
        'role': 'member',
        'joinStatus': 'pending',
      });

      return {
        'success': true,
        'message': 'Join request sent! Waiting for admin approval.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to send request: $e'};
    }
  }

  // Get mess data
  static Future<Map<String, dynamic>?> getMessData() async {
    try {
      final userData = await FirebaseAuthService.getUserData();
      if (userData == null) return null;

      final messId = userData['messId'];
      if (messId == null) return null;

      final messDoc = await _firestore.collection('messes').doc(messId).get();
      if (!messDoc.exists) return null;

      return messDoc.data();
    } catch (e) {
      return null;
    }
  }

  // Get mess name
  static Future<String> getMessName() async {
    try {
      final messData = await getMessData();
      return messData?['name'] ?? 'Test Mess';
    } catch (e) {
      return 'Test Mess';
    }
  }

  // Get mess ID
  static Future<String> getMessId() async {
    try {
      final userData = await FirebaseAuthService.getUserData();
      final messId = userData?['messId'] ?? '';
      return messId;
    } catch (e) {
      return '';
    }
  }

  // Check if user is manager
  static Future<bool> isManager() async {
    try {
      final userData = await FirebaseAuthService.getUserData();
      return userData?['role'] == 'manager';
    } catch (e) {
      return false;
    }
  }

  // Get mess members
  static Future<List<Map<String, dynamic>>> getMessMembers() async {
    try {
      final messData = await getMessData();
      if (messData == null) return [];

      final memberIds = List<String>.from(messData['members'] ?? []);
      final members = <Map<String, dynamic>>[];

      for (final memberId in memberIds) {
        final userDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userData['id'] = memberId;
          members.add(userData);
        }
      }

      return members;
    } catch (e) {
      return [];
    }
  }

  // Stream mess data (real-time updates)
  static Stream<DocumentSnapshot>? getMessStream() {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null) return null;

      return _firestore.collection('users').doc(userId).snapshots().asyncMap((
        userDoc,
      ) async {
        final messId = userDoc.data()?['messId'];
        if (messId == null) return userDoc;

        return await _firestore.collection('messes').doc(messId).get();
      });
    } catch (e) {
      return null;
    }
  }

  // Leave mess
  static Future<Map<String, dynamic>> leaveMess() async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userData = await FirebaseAuthService.getUserData();
      final messId = userData?['messId'];

      if (messId == null) {
        return {'success': false, 'message': 'Not in any mess'};
      }

      // Remove user from mess members
      await _firestore.collection('messes').doc(messId).update({
        'members': FieldValue.arrayRemove([userId]),
      });

      // Clear user's messId
      await FirebaseAuthService.updateUserData({
        'messId': null,
        'role': 'member',
      });

      return {'success': true, 'message': 'Left mess successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to leave mess: $e'};
    }
  }
}
