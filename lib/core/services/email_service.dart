import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // EmailJS Configuration
  // Get these from: https://www.emailjs.com/
  static const String _serviceId = 'service_54jp6ru';
  static const String _templateId = 'template_nauz08m';
  static const String _publicKey = 'yxfv0dFu6Lq67B37E';

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via EmailJS (Real Email)
  static Future<Map<String, dynamic>> sendOTPEmail({
    required String email,
    required String otp,
    required String name,
  }) async {
    try {
      // Check if EmailJS is configured
      if (_serviceId == 'YOUR_SERVICE_ID' ||
          _templateId == 'YOUR_TEMPLATE_ID' ||
          _publicKey == 'YOUR_PUBLIC_KEY') {
        print('⚠️  EmailJS not configured. Using demo mode.');
        return sendOTPEmailDemo(email: email, otp: otp, name: name);
      }

      // Note: EmailJS has CORS restrictions on mobile apps
      // For production, use a backend server or Firebase Cloud Functions
      // For now, using demo mode
      print('⚠️  EmailJS has restrictions on mobile apps.');
      print('⚠️  Using demo mode. Check console for OTP.');
      return sendOTPEmailDemo(email: email, otp: otp, name: name);

      /* Uncomment this when using a backend server
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': email,
            'to_name': name,
            'otp_code': otp,
            'app_name': 'Meal Manager',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ OTP sent successfully to $email');
        return {'success': true, 'message': 'OTP sent to $email'};
      } else {
        print('❌ Failed to send OTP: ${response.body}');
        return sendOTPEmailDemo(email: email, otp: otp, name: name);
      }
      */
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return sendOTPEmailDemo(email: email, otp: otp, name: name);
    }
  }

  // For development/testing - simulate OTP sending
  static Future<Map<String, dynamic>> sendOTPEmailDemo({
    required String email,
    required String otp,
    required String name,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    print('=================================');
    print('📧 OTP EMAIL (DEMO MODE)');
    print('=================================');
    print('To: $email');
    print('Name: $name');
    print('OTP Code: $otp');
    print('=================================');
    print('⚠️  Configure EmailJS to send real emails');
    print('See: EMAILJS_SETUP.md');
    print('=================================');

    return {
      'success': true,
      'message': 'OTP sent successfully (Demo Mode)',
      'otp': otp, // For testing only
    };
  }

  // Verify OTP
  static bool verifyOTP(String enteredOTP, String actualOTP) {
    return enteredOTP == actualOTP;
  }
}
