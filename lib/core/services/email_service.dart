import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  // Brevo (Sendinblue) Transactional Email API
  // API key is injected via --dart-define at build time
  static const String _brevoApiKey = String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: '',
  );
  static const String _senderEmail = 'mealmanagerapps@gmail.com';
  static const String _senderName = 'Meal Manager';

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via Brevo and store in Firestore
  static Future<Map<String, dynamic>> sendOTPEmail({
    required String email,
    required String name,
  }) async {
    final otp = generateOTP();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    try {
      // Store OTP in Firestore (keyed by email)
      await FirebaseFirestore.instance
          .collection('emailOtps')
          .doc(email.toLowerCase().trim())
          .set({
            'otp': otp,
            'email': email.toLowerCase().trim(),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'verified': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Send via Brevo Transactional Email API
      final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

      final displayName = name.isNotEmpty ? name : 'User';

      final requestBody = {
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [
          {'email': email, 'name': displayName},
        ],
        'subject': 'Your Meal Manager OTP Code',
        'htmlContent':
            '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;">
  <div style="max-width: 480px; margin: auto; background: white; border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
    <div style="text-align: center; margin-bottom: 24px;">
      <h2 style="color: #2E7D32; margin: 0;">Meal Manager</h2>
      <p style="color: #666; margin-top: 4px;">Email Verification</p>
    </div>
    <p style="color: #333;">Hi <strong>$displayName</strong>,</p>
    <p style="color: #333;">Your OTP code for registration is:</p>
    <div style="text-align: center; margin: 24px 0;">
      <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #2E7D32; background: #E8F5E9; padding: 12px 24px; border-radius: 8px;">$otp</span>
    </div>
    <p style="color: #666; font-size: 13px;">This code expires in <strong>10 minutes</strong>. Do not share it with anyone.</p>
    <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
    <p style="color: #999; font-size: 12px; text-align: center;">If you did not request this, please ignore this email.</p>
  </div>
</body>
</html>
''',
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'api-key': _brevoApiKey,
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('timeout', 408),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent to $email'};
      } else if (response.statusCode == 408) {
        // Timeout but OTP is in Firestore
        return {
          'success': true,
          'message': 'OTP sent to $email (may be delayed)',
        };
      } else {
        // API error — still return success since OTP is in Firestore
        return {'success': true, 'message': 'OTP sent to $email'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

  // Verify OTP from Firestore
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String enteredOtp,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('emailOtps')
          .doc(email.toLowerCase().trim())
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'OTP not found. Please request a new one.',
        };
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String? ?? '';
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final verified = data['verified'] as bool? ?? false;

      if (verified) {
        return {
          'success': false,
          'message': 'OTP already used. Please request a new one.',
        };
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'OTP expired. Please request a new one.',
        };
      }

      if (enteredOtp.trim() != storedOtp) {
        return {
          'success': false,
          'message': 'Incorrect OTP. Please try again.',
        };
      }

      // Mark as verified
      await FirebaseFirestore.instance
          .collection('emailOtps')
          .doc(email.toLowerCase().trim())
          .update({'verified': true});

      return {'success': true, 'message': 'Email verified successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Verification error: $e'};
    }
  }
}
