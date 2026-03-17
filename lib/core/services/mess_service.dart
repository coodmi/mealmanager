import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class MessService {
  static const String _messIdKey = 'mess_id';
  static const String _messNameKey = 'mess_name';
  static const String _messAddressKey = 'mess_address';
  static const String _messDistrictKey = 'mess_district';
  static const String _isManagerKey = 'is_manager';

  // Generate Mess ID (MM1000+)
  static String generateMessId() {
    final random = Random();
    final number = 1000 + random.nextInt(99000); // MM1000 to MM99999
    return 'MM$number';
  }

  // Create new mess
  static Future<Map<String, dynamic>> createMess({
    required String messName,
    required String address,
    required String district,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messId = generateMessId();

      await prefs.setString(_messIdKey, messId);
      await prefs.setString(_messNameKey, messName);
      await prefs.setString(_messAddressKey, address);
      await prefs.setString(_messDistrictKey, district);
      await prefs.setBool(_isManagerKey, true);

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
      final prefs = await SharedPreferences.getInstance();

      // In real app, validate messId with backend
      await prefs.setString(_messIdKey, messId);
      await prefs.setBool(_isManagerKey, false);

      return {'success': true, 'message': 'Joined mess successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to join mess: $e'};
    }
  }

  // Get mess data
  static Future<Map<String, String?>> getMessData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'messId': prefs.getString(_messIdKey),
      'messName': prefs.getString(_messNameKey),
      'address': prefs.getString(_messAddressKey),
      'district': prefs.getString(_messDistrictKey),
    };
  }

  // Get mess name
  static Future<String> getMessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_messNameKey) ?? 'My Mess';
  }

  // Check if user is manager
  static Future<bool> isManager() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isManagerKey) ?? false;
  }

  // Clear mess data
  static Future<void> clearMessData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messIdKey);
    await prefs.remove(_messNameKey);
    await prefs.remove(_messAddressKey);
    await prefs.remove(_messDistrictKey);
    await prefs.remove(_isManagerKey);
  }
}
