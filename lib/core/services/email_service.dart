import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static const String _serviceId = 'service_54jp6ru';
  static const String _templateId = 'template_w3o8w33';
  static const String _publicKey = 'fS2-nAnQ2CSIsRFcy';

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

    // DEBUG: Print OTP to console (remove in production)
    print('═══════════════════════════════════════════════════════');
    print('🔐 OTP GENERATED FOR DEVELOPMENT');
    print('═══════════════════════════════════════════════════════');
    print('📧 Email: $email');
    print('🔢 OTP: $otp');
    print('⏰ Expires: ${expiresAt.toLocal()}');
    print('═══════════════════════════════════════════════════════');

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

      print('✅ OTP stored in Firestore successfully');

      // Send via EmailJS REST API with timeout
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      try {
        print('📤 Attempting to send email via EmailJS...');
        print('   Service ID: $_serviceId');
        print('   Template ID: $_templateId');
        print('   Public Key: $_publicKey');

        final requestBody = {
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': email,
            'to_name': name.isNotEmpty ? name : 'User',
            'otp_code': otp,
            'expire_minutes': '10',
          },
        };

        print('   Request body: ${json.encode(requestBody)}');

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(requestBody),
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⏱️  Email sending timed out (10 seconds)');
                return http.Response('timeout', 408);
              },
            );

        if (response.statusCode == 200) {
          print('✅ Email sent successfully via EmailJS');
          return {'success': true, 'message': 'OTP sent to $email'};
        } else if (response.statusCode == 408) {
          print('⚠️  Email timeout - but OTP is in Firestore');
          return {
            'success': true,
            'message': 'OTP sent to $email (email may be delayed)',
          };
        } else {
          print('⚠️  EmailJS returned status: ${response.statusCode}');
          print('   Response: ${response.body}');
          return {
            'success': true,
            'message': 'OTP sent to $email (email may be delayed)',
          };
        }
      } catch (emailError) {
        print('⚠️  Email sending failed: $emailError');
        print('   But OTP is stored in Firestore - user can still verify');
        return {
          'success': true,
          'message': 'OTP sent to $email (email may be delayed)',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
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
