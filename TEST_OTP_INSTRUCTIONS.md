# OTP Email Testing Instructions

## Current Status
✅ EmailJS Configuration Updated:
- Service ID: `service_54jp6ru`
- Template ID: `template_w3o8w33`
- Public Key: `_RbqM-xvVUUpecU7R`

## Issue Identified
❌ Gmail API authentication expired in EmailJS
- Error: "Gmail_API: Invalid grant. Please reconnect your Gmail account"

## Fix Steps

### Step 1: Reconnect Gmail in EmailJS
1. Go to: https://dashboard.emailjs.com/
2. Click on **Email Services** in the left sidebar
3. Find service: `service_54jp6ru`
4. Click **"Edit"** or **"Reconnect"** button
5. Sign in with Gmail: `asifmollik93@gmail.com`
6. Grant all permissions when prompted
7. Click **"Save"** or **"Update"**

### Step 2: Test Registration
1. Run the app: `flutter run -d chrome`
2. Go to registration page
3. Enter email: `asifmollik93@gmail.com`
4. Enter name and password
5. Click "Create Account"

### Step 3: Check OTP
The OTP will appear in **TWO PLACES**:

#### A. Flutter Console (Development Mode)
```
═══════════════════════════════════════════════════════════
🔐 OTP GENERATED FOR DEVELOPMENT
═══════════════════════════════════════════════════════════
📧 Email: asifmollik93@gmail.com
🔢 OTP: 123456
⏰ Expires: 2026-04-21 05:14:33
═══════════════════════════════════════════════════════════
```

#### B. Gmail Inbox
- Check inbox for email from your EmailJS service
- Subject: "Your OTP Code" (or similar based on template)
- The 6-digit OTP will be in the email body

### Step 4: Verify OTP
1. Copy the OTP from console or email
2. Paste it in the OTP verification screen
3. Click "Verify"

## Troubleshooting

### If Email Still Doesn't Arrive:
1. **Check Gmail Spam/Junk folder**
2. **Verify EmailJS Dashboard shows "Connected" status** for Gmail service
3. **Check EmailJS usage limits** (free tier: 200 emails/month)
4. **Try with a different email** to rule out email-specific issues

### If OTP Verification Fails:
1. Make sure you're using the OTP within 10 minutes
2. Check that you copied the full 6-digit code
3. OTP can only be used once - request a new one if needed

### If Registration Still Hangs:
1. Check browser console for errors (F12 → Console tab)
2. Check Flutter console for detailed logs
3. Verify Firestore rules allow public read on `users` collection

## Current Firestore Rules (Already Fixed)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow public read for registration checks
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /deleted_users/{userId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write their OTP
    match /emailOtps/{email} {
      allow read, write: if true;
    }
  }
}
```

## Success Indicators
✅ Console shows: "✅ OTP stored in Firestore successfully"
✅ Console shows: "✅ Email sent successfully via EmailJS"
✅ Email arrives in Gmail inbox within 30 seconds
✅ OTP verification succeeds
✅ User account created in Firebase Authentication
✅ User document created in Firestore `users` collection

## Next Steps After Fix
Once Gmail is reconnected and OTP emails are working:
1. Test with your email: asifmollik93@gmail.com
2. Test with a different email to confirm it works for all users
3. Remove console OTP logging before production deployment
