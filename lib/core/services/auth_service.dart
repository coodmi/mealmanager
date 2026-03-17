import 'package:shared_preferences/shared_preferences.dart';
import 'email_service.dart';
import 'firebase_auth_service.dart';

class AuthService {
  static const String _otpKey = 'stored_otp';
  static const String _emailKey = 'user_email';
  static const String _nameKey = 'user_name';
  static const String _mobileKey = 'user_mobile';
  static const String _passwordKey = 'user_password';

  // Register user and send OTP
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    try {
      // Generate OTP
      final otp = EmailService.generateOTP();

      // Send OTP via email (will auto-switch to demo if not configured)
      final result = await EmailService.sendOTPEmail(
        email: email,
        otp: otp,
        name: name,
      );

      if (result['success']) {
        // Store OTP and user data temporarily
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_otpKey, otp);
        await prefs.setString(_emailKey, email);
        await prefs.setString(_nameKey, name);
        await prefs.setString(_mobileKey, mobile);
        await prefs.setString(_passwordKey, password);

        return {
          'success': true,
          'message': 'OTP sent to $email',
          'otp': otp, // For testing - remove in production
        };
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Login user (delegates to Firebase)
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuthService.loginUser(
      email: email,
      password: password,
    );
  }

  // Get user data (delegates to Firebase)
  static Future<Map<String, dynamic>?> getUserData() async {
    return await FirebaseAuthService.getUserData();
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(String enteredOTP) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOTP = prefs.getString(_otpKey);

      if (storedOTP == null) {
        return {'success': false, 'message': 'OTP expired or not found'};
      }

      if (EmailService.verifyOTP(enteredOTP, storedOTP)) {
        // Clear OTP after successful verification
        await prefs.remove(_otpKey);

        return {'success': true, 'message': 'OTP verified successfully'};
      } else {
        return {'success': false, 'message': 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  // Get stored email
  static Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Clear all auth data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }
}
