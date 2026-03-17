# 📧 EmailJS Visual Setup Guide

## 🎯 Goal: Send Real OTP Emails in 5 Minutes

Follow these exact steps with screenshots locations.

---

## Step 1: Create EmailJS Account

### 1.1 Go to Website
```
🌐 Open: https://www.emailjs.com/
```

### 1.2 Sign Up
```
📍 Location: Top right corner
🖱️ Click: "Sign Up" button
✅ Choose: "Sign up with Google" (recommended)
   OR
✅ Enter: Email and Password
```

### 1.3 Verify Email
```
📧 Check your email inbox
🖱️ Click verification link
✅ Account activated!
```

---

## Step 2: Add Email Service (Gmail)

### 2.1 Navigate to Services
```
📍 Location: Left sidebar
🖱️ Click: "Email Services"
```

### 2.2 Add New Service
```
📍 Location: Center of page
🖱️ Click: "Add New Service" button
```

### 2.3 Choose Gmail
```
📍 Location: Service providers list
🖱️ Click: "Gmail" icon
```

### 2.4 Connect Gmail Account
```
🖱️ Click: "Connect Account" button
📧 Sign in with: MealManagerApps@gmail.com
✅ Allow: All permissions
```

### 2.5 Copy Service ID
```
📍 Location: After connection, you'll see Service ID
📋 Copy: service_xxxxxxx
💾 Save it: You'll need this!

Example: service_abc123def
```

---

## Step 3: Create Email Template

### 3.1 Navigate to Templates
```
📍 Location: Left sidebar
🖱️ Click: "Email Templates"
```

### 3.2 Create New Template
```
📍 Location: Center of page
🖱️ Click: "Create New Template" button
```

### 3.3 Configure Template

#### Template Name:
```
📝 Enter: "Meal Manager OTP"
```

#### Email Subject:
```
📝 Enter: Meal Manager - Your OTP Code
```

#### Email Body (Copy this exactly):
```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9fff7;">
  <div style="background-color: #177c60; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
    <h1 style="color: white; margin: 0;">🍽️ Meal Manager</h1>
  </div>
  
  <div style="background-color: white; padding: 30px; border-radius: 0 0 10px 10px;">
    <h2 style="color: #177c60;">Hello {{to_name}}!</h2>
    
    <p style="color: #2c3e50; font-size: 16px;">
      Welcome to Meal Manager. Your OTP for registration is:
    </p>
    
    <div style="background-color: #f9fff7; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; border: 2px dashed #177c60;">
      <h1 style="color: #11835b; font-size: 36px; letter-spacing: 8px; margin: 0;">
        {{otp_code}}
      </h1>
    </div>
    
    <p style="color: #7f8c8d; font-size: 14px;">
      ⏰ This OTP is valid for 10 minutes.
    </p>
    
    <p style="color: #7f8c8d; font-size: 14px;">
      If you didn't request this, please ignore this email.
    </p>
    
    <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 30px 0;">
    
    <div style="text-align: center; color: #95a5a6; font-size: 12px;">
      <p><strong>Meal Manager</strong><br>
      Manage Meals, Deposits & Expenses Smartly</p>
      <p>📧 MealManagerApps@gmail.com</p>
    </div>
  </div>
</div>
```

#### Template Settings:
```
📍 Location: Settings tab
✅ Make sure these variables exist:
   - to_email
   - to_name
   - otp_code
   - app_name
```

### 3.4 Save Template
```
🖱️ Click: "Save" button (top right)
```

### 3.5 Copy Template ID
```
📍 Location: After saving, you'll see Template ID
📋 Copy: template_xxxxxxx
💾 Save it: You'll need this!

Example: template_xyz789abc
```

---

## Step 4: Get Public Key

### 4.1 Navigate to Account
```
📍 Location: Top right corner
🖱️ Click: Your profile icon
🖱️ Select: "Account"
```

### 4.2 Find Public Key
```
📍 Location: "General" tab
📍 Section: "Public Key"
📋 Copy: Your public key
💾 Save it: You'll need this!

Example: AbCdEfGhIjKlMnOp1234
```

---

## Step 5: Update Flutter Code

### 5.1 Open File
```
📂 Navigate to: lib/core/services/email_service.dart
```

### 5.2 Find These Lines (around line 8-10):
```dart
static const String _serviceId = 'YOUR_SERVICE_ID';
static const String _templateId = 'YOUR_TEMPLATE_ID';
static const String _publicKey = 'YOUR_PUBLIC_KEY';
```

### 5.3 Replace With Your IDs:
```dart
static const String _serviceId = 'service_abc123def';      // From Step 2.5
static const String _templateId = 'template_xyz789abc';    // From Step 3.5
static const String _publicKey = 'AbCdEfGhIjKlMnOp1234';   // From Step 4.2
```

### 5.4 Save File
```
💾 Save: Ctrl+S (Windows/Linux) or Cmd+S (Mac)
```

---

## Step 6: Test Real Email

### 6.1 Restart App
```bash
# Stop current app (if running)
# Then run:
flutter pub get
flutter run
```

### 6.2 Register with Real Email
```
📱 Open app
🖱️ Click: "Register" tab
📝 Fill form:
   - Name: Your Name
   - Mobile: 01712345678
   - Email: your-real-email@gmail.com  ← Use real email!
   - Password: test123
🖱️ Click: "Sign Up"
```

### 6.3 Check Email Inbox
```
📧 Open your email inbox
📬 Look for: "Meal Manager - Your OTP Code"
👀 Find OTP: 6-digit code in email
```

### 6.4 Enter OTP
```
📱 App shows: OTP verification screen
⌨️ Enter: 6-digit OTP from email
🖱️ Click: "Verify"
```

### 6.5 Success!
```
✅ Message: "OTP verified successfully"
🎉 Redirected to login screen
```

---

## 🎯 Verification Checklist

After setup, verify:

- [ ] EmailJS account created
- [ ] Gmail service connected (green checkmark)
- [ ] Email template created and saved
- [ ] Service ID copied (starts with "service_")
- [ ] Template ID copied (starts with "template_")
- [ ] Public Key copied (alphanumeric string)
- [ ] All 3 IDs updated in email_service.dart
- [ ] File saved
- [ ] App restarted
- [ ] Registered with real email
- [ ] Email received in inbox
- [ ] OTP verified successfully

---

## 🔍 How to Find Your IDs Again

### Service ID:
```
Dashboard → Email Services → Click your Gmail service
→ Service ID shown at top
```

### Template ID:
```
Dashboard → Email Templates → Click your template
→ Template ID shown at top
```

### Public Key:
```
Dashboard → Account (top right) → General tab
→ Public Key section
```

---

## 📧 Test Email Preview

When you register, user will receive:

```
From: MealManagerApps@gmail.com (via EmailJS)
To: user@example.com
Subject: Meal Manager - Your OTP Code

┌─────────────────────────────────────┐
│      🍽️ Meal Manager                │
└─────────────────────────────────────┘

Hello John Doe!

Welcome to Meal Manager. Your OTP for 
registration is:

┌─────────────────────────────────────┐
│                                     │
│          8 4 7 2 9 3                │
│                                     │
└─────────────────────────────────────┘

⏰ This OTP is valid for 10 minutes.

If you didn't request this, please 
ignore this email.

─────────────────────────────────────
Meal Manager
Manage Meals, Deposits & Expenses Smartly
📧 MealManagerApps@gmail.com
```

---

## 🐛 Troubleshooting

### Problem: "YOUR_SERVICE_ID" error
```
❌ You didn't update the IDs
✅ Solution: Update all 3 IDs in email_service.dart
```

### Problem: Email not received
```
❌ Check spam folder
❌ Verify email address is correct
❌ Check EmailJS dashboard for errors
✅ Solution: Check "Logs" in EmailJS dashboard
```

### Problem: "Failed to send OTP"
```
❌ Service ID incorrect
❌ Template ID incorrect
❌ Public Key incorrect
✅ Solution: Double-check all 3 IDs
```

### Problem: Still showing demo mode
```
❌ IDs not updated
❌ App not restarted
✅ Solution: 
   1. Update IDs
   2. Save file
   3. Stop app
   4. Run: flutter pub get
   5. Run: flutter run
```

---

## 📊 EmailJS Dashboard

After sending emails, check dashboard:

### Email Logs:
```
Dashboard → Logs
→ See all sent emails
→ Check delivery status
→ View error messages
```

### Usage Stats:
```
Dashboard → Account → Usage
→ See emails sent this month
→ Check remaining quota
→ Free: 200 emails/month
```

---

## 🎉 You're Done!

Your app now sends real OTP emails!

**Test it:**
1. Register with real email
2. Check inbox
3. Enter OTP
4. Success!

**Next steps:**
- Test with multiple emails
- Monitor EmailJS dashboard
- Upgrade plan if needed (200+ emails/month)

---

## 📞 Support

**EmailJS Issues:**
- Dashboard: https://dashboard.emailjs.com/
- Docs: https://www.emailjs.com/docs/
- Support: support@emailjs.com

**App Issues:**
- Check console for errors
- See EMAILJS_SETUP.md for details
- Verify all 3 IDs are correct

---

## ⚡ Quick Reference

```
Service ID:    service_xxxxxxx
Template ID:   template_xxxxxxx
Public Key:    xxxxxxxxxxxxxxxx

Update in:     lib/core/services/email_service.dart
Lines:         8-10

Test command:  flutter pub get && flutter run
```

---

**Total Setup Time:** ~5 minutes ⏱️
**Difficulty:** Easy ⭐
**Cost:** Free (200 emails/month) 💰

Happy coding! 🚀
