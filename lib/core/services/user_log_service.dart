import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLogService {
  static Future<void> log({required String action, String details = ''}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};

      await FirebaseFirestore.instance.collection('userLogs').add({
        'userId': user.uid,
        'userName': data['name'] ?? user.displayName ?? '—',
        'userEmail': data['email'] ?? user.email ?? '—',
        'userMobile': data['mobile'] ?? '—',
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Logging should never crash the app
    }
  }
}
