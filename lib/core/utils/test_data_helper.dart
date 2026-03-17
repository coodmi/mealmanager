import '../services/firebase_mess_service.dart';
import '../../features/member/data/models/member_model.dart';
import '../../features/member/data/services/firebase_member_service.dart';

class TestDataHelper {
  static Future<void> addTestMembers() async {
    try {
      final messId = await FirebaseMessService.getMessId();

      if (messId.isEmpty) {
        print('No mess ID found');
        return;
      }

      // Check if members already exist
      final existingMembers = await FirebaseMemberService.getActiveMembers(
        messId,
      ).first;

      if (existingMembers.isNotEmpty) {
        print('Members already exist');
        return;
      }

      // Add test members
      final testMembers = [
        MemberModel(
          id: '',
          name: 'John Doe',
          phone: '+880 1712-345678',
          messId: messId,
          balance: 1250,
          isActive: true,
          joinedDate: DateTime.now(),
        ),
        MemberModel(
          id: '',
          name: 'Jane Smith',
          phone: '+880 1812-345678',
          messId: messId,
          balance: 2100,
          isActive: true,
          joinedDate: DateTime.now(),
        ),
        MemberModel(
          id: '',
          name: 'Mike Johnson',
          phone: '+880 1912-345678',
          messId: messId,
          balance: -500,
          isActive: true,
          joinedDate: DateTime.now(),
        ),
        MemberModel(
          id: '',
          name: 'Sarah Williams',
          phone: '+880 1612-345678',
          messId: messId,
          balance: 3200,
          isActive: true,
          joinedDate: DateTime.now(),
        ),
      ];

      for (final member in testMembers) {
        await FirebaseMemberService.addMember(member);
      }

      print('Test members added successfully');
    } catch (e) {
      print('Error adding test members: $e');
    }
  }
}
