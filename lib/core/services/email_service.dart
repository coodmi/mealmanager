import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static const String _serviceId = 'service_54jp6ru';
  static const String _templateId = 'template_w3o8w33';
  static const String _publicKey = 'yxfv0dFu6Lq67B37E';

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via EmailJS and store in Firestore
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

      // Send via EmailJS REST API
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': email,
            'to_name': name.isNotEmpty ? name : 'User',
            'otp_code': otp,
            'app_name': 'Meal Manager',
            'expire_minutes': '10',
          },
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent to $email'};
      } else {
        // EmailJS failed — still return success since OTP is in Firestore
        // User can use resend. Log the error body for debugging.
        return {
          'success': false,
          'message':
              'Failed to send email. Please try again. (${response.body})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
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
