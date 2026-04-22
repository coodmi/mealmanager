# OTP Email Not Received - Solutions

## 🔍 Problem

You're not receiving the OTP email, but the OTP is still stored in Firestore and can be used for verification.

## ✅ Solution 1: Check Flutter Console (Easiest)

I've added console logging to display the OTP during development.

### Steps:
1. **Look at your Flutter console** (where you ran `flutter run`)
2. **Find the OTP** in the console output:
   ```
   ═══════════════════════════════════════════════════════
   🔐 OTP GENERATED FOR DEVELOPMENT
   ═══════════════════════════════════════════════════════
   📧 Email: your@email.com
   🔢 OTP: 123456  ← USE THIS
   ⏰ Expires: 2026-04-21 15:30:00
   ═══════════════════════════════════════════════════════
   ```
3. **Copy the 6-digit OTP**
4. **Enter it in the OTP dialog**
5. **Account created!** ✅

## ✅ Solution 2: Check Firestore Console

### Steps:
1. **Open Firestore Console**:
   https://console.firebase.google.com/project/mealmanager-6a053/firestore

2. **Go to `emailOtps` collection**

3. **Find your email document**

4. **Copy the `otp` field value**

5. **Enter it in the OTP dialog**

## ✅ Solution 3: Use Node.js Script

### Steps:
```bash
# Check OTP for your email
node check_otp.js your@email.com
```

This will display:
```
╔════════════════════════════════════════════════════════╗
║                    OTP INFORMATION                     ║
╚════════════════════════════════════════════════════════╝

📧 Email: your@email.com
🔢 OTP: 123456
⏰ Expires: 4/21/2026, 3:30:00 PM
✅ Verified: No
⏳ Status: VALID

✅ You can use this OTP to verify your account!
```

## 🔍 Why Email Isn't Arriving

### Possible Reasons:

1. **EmailJS Service Issues**
   - The EmailJS API might be slow or down
   - Rate limiting on free tier
   - Service configuration issues

2. **Email Provider Blocking**
   - Gmail/Outlook might block automated emails
   - Emails going to spam folder
   - Email provider security settings

3. **Network Issues**
   - Timeout after 10 seconds
   - Firewall blocking EmailJS API
   - CORS issues in browser

## ✅ Workaround (Current Solution)

**The app now logs OTP to console**, so you can:
1. Register normally
2. Check Flutter console for OTP
3. Enter OTP from console
4. Complete registration

**This works perfectly for development!**

## 🔧 For Production

### Option 1: Fix EmailJS Configuration

1. **Check EmailJS Dashboard**:
   - Go to: https://dashboard.emailjs.com/
   - Verify service is active
   - Check email template
   - Verify public key

2. **Update Credentials** (if needed):
   ```dart
   // In lib/core/services/email_service.dart
   static const String _serviceId = 'your_service_id';
   static const String _templateId = 'your_template_id';
   static const String _publicKey = 'your_public_key';
   ```

### Option 2: Use Alternative Email Service

Consider switching to:
- **SendGrid** - More reliable
- **AWS SES** - Better for production
- **Twilio SendGrid** - Enterprise grade
- **Firebase Email Extension** - Native integration

### Option 3: Add SMS OTP

Add SMS as backup:
- **Twilio** - SMS OTP
- **Firebase Phone Auth** - Built-in
- **AWS SNS** - SMS service

## 📊 Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| OTP Generation | ✅ Working | OTP created successfully |
| Firestore Storage | ✅ Working | OTP stored in database |
| Email Sending | ⚠️ Unreliable | EmailJS may fail |
| Console Logging | ✅ Added | OTP shown in console |
| OTP Verification | ✅ Working | Can verify from Firestore |

## 🎯 Quick Test

1. **Run app**: `flutter run -d chrome`
2. **Register** with any email
3. **Check Flutter console** for OTP
4. **Copy OTP** from console
5. **Enter in dialog**
6. **Account created!** ✅

## 📝 Example Console Output

When you register, you'll see:
```
═══════════════════════════════════════════════════════
🔐 OTP GENERATED FOR DEVELOPMENT
═══════════════════════════════════════════════════════
📧 Email: test@example.com
🔢 OTP: 456789
⏰ Expires: 2026-04-21 15:45:00.000
═══════════════════════════════════════════════════════
✅ OTP stored in Firestore successfully
📤 Attempting to send email via EmailJS...
⚠️  Email timeout - but OTP is in Firestore
```

**Just use the OTP: 456789**

## ✅ Recommended Approach

**For now (Development):**
- Use console logging ✅
- Check Firestore if needed ✅
- Registration works perfectly ✅

**For production:**
- Fix EmailJS configuration
- Or switch to more reliable service
- Add SMS backup option

## 🎉 Bottom Line

**You can still register successfully!**

Just check the Flutter console for the OTP instead of waiting for email. The registration process works perfectly - the email delivery is the only issue, and we have a workaround.

---

**Updated**: April 21, 2026  
**Status**: ✅ Workaround implemented  
**Console logging**: Added  
**Registration**: Fully functional
