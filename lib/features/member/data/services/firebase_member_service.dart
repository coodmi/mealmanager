import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class FirebaseMemberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all members for a mess
  static Stream<List<MemberModel>> getMembers(String messId) {
    return _firestore
        .collection('members')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snapshot) {
          var members = snapshot.docs
              .map((doc) => MemberModel.fromFirestore(doc))
              .toList();
          // Sort by name in memory
          members.sort((a, b) => a.name.compareTo(b.name));
          return members;
        });
  }

  // Get active members only
  static Stream<List<MemberModel>> getActiveMembers(String messId) {
    return _firestore
        .collection('members')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snapshot) {
          var members = snapshot.docs
              .map((doc) => MemberModel.fromFirestore(doc))
              .where((member) => member.isActive) // Filter active in memory
              .toList();
          // Sort by name in memory
          members.sort((a, b) => a.name.compareTo(b.name));
          return members;
        });
  }

  // Get a single member
  static Future<MemberModel?> getMember(String memberId) async {
    try {
      final doc = await _firestore.collection('members').doc(memberId).get();
      if (doc.exists) {
        return MemberModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get member: $e');
    }
  }

  // Add a new member
  static Future<String> addMember(MemberModel member) async {
    try {
      final docRef = await _firestore
          .collection('members')
          .add(member.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  // Update member
  static Future<void> updateMember(
    String memberId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('members').doc(memberId).update(updates);
    } catch (e) {
      throw Exception('Failed to update member: $e');
    }
  }

  // Update member balance
  static Future<void> updateBalance(String memberId, double amount) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        'balance': FieldValue.increment(amount),
      });
    } catch (e) {
      throw Exception('Failed to update balance: $e');
    }
  }

  // Delete member
  static Future<void> deleteMember(String memberId) async {
    try {
      await _firestore.collection('members').doc(memberId).delete();
    } catch (e) {
      throw Exception('Failed to delete member: $e');
    }
  }

  // Toggle member active status
  static Future<void> toggleActiveStatus(String memberId, bool isActive) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to toggle active status: $e');
    }
  }
}
