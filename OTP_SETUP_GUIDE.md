# OTP Email Setup - Quick Start Guide

## ✅ What's Working Now

The OTP system is **fully functional** in DEMO MODE:

1. User registers with email
2. OTP is generated (6-digit random number)
3. OTP is printed to console
4. OTP is shown in SnackBar (for testing)
5. OTP is stored in SharedPreferences
6. User enters OTP on verification screen
7. OTP is verified
8. User redirected to login

## 🧪 How to Test (Demo Mode)

### Step 1: Run the app
```bash
flutter pub get
flutter run
```

### Step 2: Register
1. Open the app
2. Click "Register" tab
3. Fill in:
   - Name: Test User
   - Mobile: 01712345678
   - Email: your-email@example.com
   - Password: test123
4. Click "Sign Up"

### Step 3: Check Console
Look for output like:
```
=================================
📧 OTP EMAIL (DEMO MODE)
=================================
To: your-email@example.com
Name: Test User
OTP Code: 123456
=================================
```

### Step 4: Check SnackBar
A green SnackBar will show:
```
OTP sent to your-email@example.com
OTP: 123456 (Check console)
```

### Step 5: Enter OTP
1. You'll be redirected to OTP verification screen
2. Enter the 6-digit OTP from console/snackbar
3. Click "Verify"

### Step 6: Success
- Green message: "OTP verified successfully"
- Redirected to login screen

## 📧 To Send Real Emails

You have 3 options:

### Option 1: Quick Setup with Gmail (5 minutes)

1. **Create Node.js backend** (see BACKEND_SETUP.md)
2. **Get Gmail App Password**:
   - Go to https://myaccount.google.com/security
   - Enable 2-Step Verification
   - Go to App Passwords
   - Select "Mail" and generate
   - Copy the 16-character password

3. **Update backend .env**:
```
EMAIL_USER=MealManagerApps@gmail.com
EMAIL_PASS=your_16_char_app_password
```

4. **Run backend**:
```bash
cd meal-manager-backend
node server.js
```

5. **Update Flutter app**:
In `lib/core/services/email_service.dart`, line 16:
```dart
Uri.parse('http://localhost:3000/send-otp'),  // Local testing
// or
Uri.parse('https://your-server.com/send-otp'),  // Production
```

6. **Switch to real mode**:
In `lib/core/services/auth_service.dart`, line 19:
```dart
// Change from:
final result = await EmailService.sendOTPEmailDemo(

// To:
final result = await EmailService.sendOTPEmail(
```

### Option 2: Firebase (Recommended for Production)

See BACKEND_SETUP.md for Firebase setup

### Option 3: Third-Party Services

- SendGrid (Free: 100 emails/day)
- Mailgun (Free: 5,000 emails/month)
- AWS SES (Very cheap)

## 🔍 Troubleshooting

### OTP not showing in console?
- Check if you're on Register tab (not Login)
- Make sure you filled all fields
- Check terminal/console output

### OTP verification fails?
- Make sure you entered the exact OTP from console
- OTP is case-sensitive (numbers only)
- Check if OTP expired (currently no expiry in demo)

### Want to test multiple times?
- Just register again with same/different email
- Each registration generates new OTP
- Old OTP is replaced

## 🎯 Current Features

✅ OTP Generation (6-digit random)
✅ OTP Storage (SharedPreferences)
✅ OTP Verification
✅ Console Output (Demo)
✅ SnackBar Display (Testing)
✅ Auto-focus on OTP fields
✅ Loading states
✅ Error handling
✅ Success/Error messages

## 🚀 Next Steps

To make it production-ready:

1. Set up backend (Node.js/Firebase)
2. Configure email service (Gmail/SendGrid)
3. Add OTP expiry (10 minutes)
4. Add resend OTP functionality
5. Remove OTP from response
6. Add rate limiting
7. Deploy backend to cloud

## 📝 Notes

- Demo mode is perfect for development
- No backend needed for testing
- OTP is visible for easy testing
- Switch to real email when ready
- All code is ready, just needs backend

## 🆘 Need Help?

Check these files:
- `lib/core/services/email_service.dart` - Email sending logic
- `lib/core/services/auth_service.dart` - Registration & verification
- `lib/features/auth/presentation/pages/login_page.dart` - Register UI
- `lib/features/auth/presentation/pages/otp_verification_page.dart` - OTP UI
- `BACKEND_SETUP.md` - Backend setup instructions

## 🎉 Summary

Your OTP system is **working perfectly** in demo mode! You can:
- Register users
- Generate OTPs
- Verify OTPs
- Test the complete flow

When you're ready for production, just set up a backend and switch from `sendOTPEmailDemo()` to `sendOTPEmail()`.
