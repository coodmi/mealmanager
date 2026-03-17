# EmailJS Setup Guide - Send Real OTP Emails

## 🎯 What is EmailJS?

EmailJS allows you to send emails directly from your Flutter app **without a backend server**. It's:
- ✅ Free (200 emails/month)
- ✅ No backend needed
- ✅ Easy setup (5 minutes)
- ✅ Works on all platforms

## 📧 Step-by-Step Setup

### Step 1: Create EmailJS Account (2 minutes)

1. Go to https://www.emailjs.com/
2. Click **"Sign Up"** (top right)
3. Sign up with Google or Email
4. Verify your email

### Step 2: Add Email Service (1 minute)

1. After login, go to **"Email Services"** (left sidebar)
2. Click **"Add New Service"**
3. Choose **Gmail** (recommended) or any other
4. Click **"Connect Account"**
5. Sign in with your Gmail (MealManagerApps@gmail.com)
6. Allow permissions
7. Copy the **Service ID** (looks like: `service_abc123`)

### Step 3: Create Email Template (2 minutes)

1. Go to **"Email Templates"** (left sidebar)
2. Click **"Create New Template"**
3. Replace the template with this:

```html
Subject: Meal Manager - OTP Verification

Body:
Hello {{to_name}},

Welcome to Meal Manager!

Your OTP for registration is:

{{otp_code}}

This OTP is valid for 10 minutes.

If you didn't request this, please ignore this email.

────────────────────────────────────
Meal Manager
Manage Meals, Deposits & Expenses Smartly
Email: MealManagerApps@gmail.com
```

4. **Template Variables** (make sure these are set):
   - `to_email` - Recipient email
   - `to_name` - Recipient name
   - `otp_code` - The OTP code
   - `app_name` - App name

5. Click **"Save"**
6. Copy the **Template ID** (looks like: `template_xyz789`)

### Step 4: Get Public Key (30 seconds)

1. Go to **"Account"** (top right) → **"General"**
2. Find **"Public Key"** section
3. Copy the **Public Key** (looks like: `AbCdEfGhIjKlMnOp`)

### Step 5: Update Flutter App (1 minute)

Open `lib/core/services/email_service.dart` and update these lines:

```dart
// Replace these with your actual values
static const String _serviceId = 'service_abc123';      // From Step 2
static const String _templateId = 'template_xyz789';    // From Step 3
static const String _publicKey = 'AbCdEfGhIjKlMnOp';   // From Step 4
```

### Step 6: Test! (30 seconds)

```bash
flutter pub get
flutter run
```

1. Register with your real email
2. Check your inbox
3. Enter OTP
4. Success! 🎉

## 📧 Email Template (Detailed)

Here's a better formatted template:

**Subject:**
```
Meal Manager - Your OTP Code
```

**Body (HTML):**
```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9fff7;">
  <div style="background-color: #177c60; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
    <h1 style="color: white; margin: 0;">🍽️ Meal Manager</h1>
  </div>
  
  <div style="background-color: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
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
      <p style="margin: 5px 0;">
        <strong>Meal Manager</strong><br>
        Manage Meals, Deposits & Expenses Smartly
      </p>
      <p style="margin: 5px 0;">
        📧 MealManagerApps@gmail.com
      </p>
    </div>
  </div>
</div>
```

**Template Variables:**
- `{{to_name}}` - User's name
- `{{to_email}}` - User's email (auto-filled)
- `{{otp_code}}` - The OTP code
- `{{app_name}}` - "Meal Manager"

## 🔍 Troubleshooting

### Problem: Emails not sending
**Solutions:**
1. Check Service ID, Template ID, and Public Key are correct
2. Make sure Gmail account is connected in EmailJS
3. Check EmailJS dashboard for error logs
4. Verify template variables match exactly

### Problem: Emails going to spam
**Solutions:**
1. Add "MealManagerApps@gmail.com" to contacts
2. Mark first email as "Not Spam"
3. Use a verified domain (paid EmailJS plan)

### Problem: "Free quota exceeded"
**Solutions:**
1. Free plan: 200 emails/month
2. Upgrade to paid plan ($7/month for 1000 emails)
3. Use multiple EmailJS accounts (not recommended)

### Problem: Still using demo mode
**Solution:**
Make sure you updated all three values in `email_service.dart`:
```dart
static const String _serviceId = 'YOUR_SERVICE_ID';      // ❌ Change this
static const String _templateId = 'YOUR_TEMPLATE_ID';    // ❌ Change this
static const String _publicKey = 'YOUR_PUBLIC_KEY';      // ❌ Change this
```

## 📊 EmailJS Dashboard

After setup, you can:
- View sent emails
- Check delivery status
- See error logs
- Monitor quota usage
- Test templates

## 🆓 Free Plan Limits

- ✅ 200 emails/month
- ✅ All features
- ✅ Multiple services
- ✅ Custom templates
- ❌ No custom domain
- ❌ EmailJS branding in emails

## 💰 Paid Plans (Optional)

**Personal ($7/month):**
- 1,000 emails/month
- Remove branding
- Priority support

**Professional ($15/month):**
- 5,000 emails/month
- Custom domain
- Advanced features

## 🔐 Security Notes

- ✅ Public Key is safe to expose (it's meant to be public)
- ✅ No sensitive data in code
- ✅ EmailJS handles authentication
- ✅ Rate limiting built-in
- ⚠️ Don't share Service ID publicly (optional security)

## 🎯 Testing Checklist

- [ ] EmailJS account created
- [ ] Gmail service connected
- [ ] Email template created
- [ ] Service ID copied
- [ ] Template ID copied
- [ ] Public Key copied
- [ ] Flutter code updated
- [ ] App restarted
- [ ] Test email sent
- [ ] OTP received in inbox
- [ ] OTP verified successfully

## 📱 Alternative: Use Your Own Backend

If you prefer more control, see `BACKEND_SETUP.md` for:
- Node.js + Nodemailer
- Firebase Cloud Functions
- AWS SES
- SendGrid API

## 🎉 You're Done!

Once configured, your app will:
1. Generate OTP
2. Send real email via EmailJS
3. User receives email in inbox
4. User enters OTP
5. Verification complete!

No backend server needed! 🚀

## 📞 Support

- EmailJS Docs: https://www.emailjs.com/docs/
- EmailJS Support: support@emailjs.com
- Check dashboard for delivery logs

---

**Quick Summary:**
1. Sign up at emailjs.com
2. Connect Gmail
3. Create template
4. Copy 3 IDs
5. Update Flutter code
6. Test!

Total time: ~5 minutes ⏱️
