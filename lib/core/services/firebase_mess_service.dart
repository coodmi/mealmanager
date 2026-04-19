import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'firebase_auth_service.dart';

class FirebaseMessService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxMesses = 3;

  static String generateMessId() {
    final random = Random();
    final number = random.nextInt(100000);
    return 'M${number.toString().padLeft(5, '0')}';
  }

  // Get all joined mess IDs for current user
  static Future<List<String>> getJoinedMessIds() async {
    try {
      final userData = await FirebaseAuthService.getUserData();
      if (userData == null) return [];
      // Support both old single messId and new messIds array
      final messIds = userData['messIds'];
      if (messIds is List) return List<String>.from(messIds);
      final messId = userData['messId'] as String? ?? '';
      if (messId.isNotEmpty) return [messId];
      return [];
    } catch (_) {
      return [];
    }
  }

  // Get mess ID (primary — first in list)
  static Future<String> getMessId() async {
    final ids = await getJoinedMessIds();
    return ids.isNotEmpty ? ids.first : '';
  }

  // Create new mess
  static Future<Map<String, dynamic>> createMess({
    required String messName,
    required String address,
    required String district,
  }) async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null)
        return {'success': false, 'message': 'User not logged in'};

      // Check max limit
      final joined = await getJoinedMessIds();
      if (joined.length >= maxMesses) {
        return {
          'success': false,
          'message':
              'You can join a maximum of $maxMesses messes at a time. Please leave a mess first.',
        };
      }

      final messId = generateMessId();
      await _firestore.collection('messes').doc(messId).set({
        'name': messName,
        'address': address,
        'district': district,
        'managerId': userId,
        'members': [userId],
        'balance': 0,
        'subscription': 'free',
        'setupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Add to messIds array
      final newIds = [...joined, messId];
      await FirebaseAuthService.updateUserData({
        'messIds': newIds,
        'messId': messId, // keep for backward compat
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

  // Join existing mess
  static Future<Map<String, dynamic>> joinMess({required String messId}) async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null)
        return {'success': false, 'message': 'User not logged in'};

      // Check max limit
      final joined = await getJoinedMessIds();
      if (joined.length >= maxMesses) {
        return {
          'success': false,
          'message':
              'You can join a maximum of $maxMesses messes at a time. Please leave a mess first.',
        };
      }

      // Already in this mess?
      if (joined.contains(messId)) {
        return {'success': false, 'message': 'You are already in this mess.'};
      }

      final messDoc = await _firestore.collection('messes').doc(messId).get();
      if (!messDoc.exists) {
        return {
          'success': false,
          'message': 'Mess not found. Check the ID and try again.',
        };
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final name = userData['name'] as String? ?? 'Unknown';
      final phone =
          userData['mobile'] as String? ?? userData['phone'] as String? ?? '';
      final email = userData['email'] as String? ?? '';

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

      // Add to messIds array
      final newIds = [...joined, messId];
      await FirebaseAuthService.updateUserData({
        'messIds': newIds,
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

  // Leave a specific mess
  static Future<Map<String, dynamic>> leaveMessById(String messId) async {
    try {
      final userId = FirebaseAuthService.getUserId();
      if (userId == null)
        return {'success': false, 'message': 'User not logged in'};

      // Remove from mess members subcollection
      await _firestore
          .collection('messes')
          .doc(messId)
          .collection('members')
          .doc(userId)
          .delete();

      // Remove from mess members array
      await _firestore.collection('messes').doc(messId).update({
        'members': FieldValue.arrayRemove([userId]),
      });

      // Remove from user's messIds
      final joined = await getJoinedMessIds();
      final newIds = joined.where((id) => id != messId).toList();
      await FirebaseAuthService.updateUserData({
        'messIds': newIds,
        'messId': newIds.isNotEmpty ? newIds.first : '',
      });

      return {'success': true, 'message': 'Left mess successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to leave mess: $e'};
    }
  }

  // Get mess data by ID
  static Future<Map<String, dynamic>?> getMessDataById(String messId) async {
    try {
      final doc = await _firestore.collection('messes').doc(messId).get();
      if (!doc.exists) return null;
      return {...doc.data()!, 'id': doc.id};
    } catch (_) {
      return null;
    }
  }

  // Get mess data (primary mess)
  static Future<Map<String, dynamic>?> getMessData() async {
    try {
      final messId = await getMessId();
      if (messId.isEmpty) return null;
      return getMessDataById(messId);
    } catch (_) {
      return null;
    }
  }

  static Future<String> getMessName() async {
    try {
      final messData = await getMessData();
      return messData?['name'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> isManager() async {
    try {
      final userData = await FirebaseAuthService.getUserData();
      return userData?['role'] == 'manager';
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMessMembers() async {
    try {
      final messId = await getMessId();
      if (messId.isEmpty) return [];
      final snap = await _firestore
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (_) {
      return [];
    }
  }

  // Legacy leave mess (leaves primary mess)
  static Future<Map<String, dynamic>> leaveMess() async {
    final messId = await getMessId();
    if (messId.isEmpty) return {'success': false, 'message': 'Not in any mess'};
    return leaveMessById(messId);
  }
}
