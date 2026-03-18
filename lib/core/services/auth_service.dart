import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'firebase_auth_service.dart';

class AuthService {
  static const String _nameKey = 'user_name';
  static const String _mobileKey = 'user_mobile';
  static const String _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _verificationIdKey = 'verification_id';

  // Web: holds the ConfirmationResult from signInWithPhoneNumber
  static ConfirmationResult? _webConfirmationResult;

  // Step 1: Send real SMS OTP via Firebase Phone Auth
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    // Store user data temporarily for after OTP verification
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_mobileKey, mobile);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);

    // Convert BD mobile to E.164 format: 017xxx → +88017xxx
    String phone = mobile.trim();
    if (phone.startsWith('0')) {
      phone = '+88$phone';
    } else if (!phone.startsWith('+')) {
      phone = '+88$phone';
    }

    try {
      if (kIsWeb) {
        // Web: Firebase auto-creates an invisible reCAPTCHA
        _webConfirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(phone);
        return {'success': true, 'autoVerified': false};
      } else {
        // Mobile: use verifyPhoneNumber callback flow
        final completer = Completer<Map<String, dynamic>>();

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) {
            if (!completer.isCompleted) {
              completer.complete({'success': true, 'autoVerified': true});
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!completer.isCompleted) {
              completer.complete({
                'success': false,
                'message': e.message ?? 'Failed to send OTP',
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) async {
            final p = await SharedPreferences.getInstance();
            await p.setString(_verificationIdKey, verificationId);
            if (!completer.isCompleted) {
              completer.complete({'success': true, 'autoVerified': false});
            }
          },
          codeAutoRetrievalTimeout: (_) {},
        );

        return completer.future;
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

  // Step 2: Verify SMS OTP → create Firebase email/password account
  static Future<Map<String, dynamic>> verifyOTP(String smsCode) async {
    try {
      UserCredential? phoneResult;

      if (kIsWeb) {
        // Web: confirm using the stored ConfirmationResult
        if (_webConfirmationResult == null) {
          return {
            'success': false,
            'message': 'Session expired. Please register again.',
          };
        }
        phoneResult = await _webConfirmationResult!.confirm(smsCode);
      } else {
        // Mobile: use verificationId from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final verificationId = prefs.getString(_verificationIdKey);
        if (verificationId == null) {
          return {
            'success': false,
            'message': 'Session expired. Please register again.',
          };
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        phoneResult = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (phoneResult.user == null) {
        return {'success': false, 'message': 'Invalid OTP'};
      }

      // Phone verified — now create the email/password account
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey) ?? '';
      final mobile = prefs.getString(_mobileKey) ?? '';
      final email = prefs.getString(_emailKey) ?? '';
      final password = prefs.getString(_passwordKey) ?? '';

      // Sign out the temporary phone session
      await FirebaseAuth.instance.signOut();
      _webConfirmationResult = null;

      final result = await FirebaseAuthService.registerUser(
        name: name,
        mobile: mobile,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        await prefs.remove(_verificationIdKey);
        await prefs.remove(_passwordKey);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return {'success': false, 'message': 'Invalid OTP. Please try again.'};
      }
      return {'success': false, 'message': e.message ?? 'Verification failed'};
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOTP() async {
    final prefs = await SharedPreferences.getInstance();
    return registerUser(
      name: prefs.getString(_nameKey) ?? '',
      mobile: prefs.getString(_mobileKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuthService.loginUser(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    return await FirebaseAuthService.signInWithGoogle();
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    return await FirebaseAuthService.getUserData();
  }

  // Get stored mobile
  static Future<String?> getStoredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  // Get stored email
  static Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Clear all auth data
  static Future<void> clearAuthData() async {
    _webConfirmationResult = null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _verificationIdKey,
      _nameKey,
      _mobileKey,
      _emailKey,
      _passwordKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
