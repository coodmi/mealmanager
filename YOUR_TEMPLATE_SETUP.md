# 📧 Your EmailJS Template Setup

## ✅ Your Credentials (Already Updated in Code)

```
Service ID:   service_54jp6ru     ✅ Updated
Template ID:  template_nauz08m    ✅ Updated
Public Key:   yxfv0dFu6Lq67B37E   ✅ Updated
```

## 📝 Now Update Your Email Template

### Step 1: Go to Your Template

1. Go to: https://dashboard.emailjs.com/admin/templates/nauz08m
2. Or: Dashboard → Email Templates → Click "One-Time Password"

### Step 2: Update Template Content

#### Subject Line:
```
Meal Manager - Your OTP Code
```

#### Email Body (Copy this exactly):

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

### Step 3: Verify Template Variables

Make sure these variables are in your template:

- `{{to_name}}` - User's name
- `{{to_email}}` - User's email (auto-filled by EmailJS)
- `{{otp_code}}` - The OTP code
- `{{app_name}}` - App name (optional)

### Step 4: Save Template

Click "Save" button (top right)

---

## 🧪 Test Your Setup

### Option 1: Test in EmailJS Dashboard

1. Go to your template
2. Click "Test it" button
3. Fill in test values:
   - `to_name`: Test User
   - `to_email`: your-email@gmail.com
   - `otp_code`: 123456
4. Click "Send Test"
5. Check your email inbox

### Option 2: Test in Flutter App

```bash
# Run the app
flutter pub get
flutter run

# Then:
1. Click "Register" tab
2. Fill form with YOUR real email
3. Click "Sign Up"
4. Check your email inbox (including spam)
5. Enter OTP from email
6. Click "Verify"
7. Success! ✅
```

---

## 📧 What Users Will Receive

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

## ✅ Verification Checklist

- [x] Service ID updated in code
- [x] Template ID updated in code
- [x] Public Key updated in code
- [ ] Email template updated with HTML
- [ ] Template variables verified
- [ ] Template saved
- [ ] Test email sent
- [ ] Test email received
- [ ] App tested with real email
- [ ] OTP verified successfully

---

## 🔍 Troubleshooting

### Problem: Email not received
**Solutions:**
1. Check spam/junk folder
2. Wait 1-2 minutes (delivery delay)
3. Verify template is saved
4. Check EmailJS dashboard logs
5. Make sure Gmail service is connected

### Problem: Template variables not showing
**Solutions:**
1. Make sure you use `{{variable_name}}` format
2. Variable names must match exactly:
   - `to_name` (not `to-name` or `toName`)
   - `to_email`
   - `otp_code`
3. Re-save template after changes

### Problem: "Failed to send OTP"
**Solutions:**
1. Check console for error message
2. Verify all 3 IDs are correct
3. Check EmailJS dashboard for errors
4. Make sure you have quota remaining (200/month free)

---

## 📊 Check Your Usage

Dashboard → Account → Usage
- Free plan: 200 emails/month
- Current usage: Check dashboard
- Upgrade if needed: $7/month for 1,000 emails

---

## 🎉 You're Almost Done!

1. ✅ Code updated with your IDs
2. ⏳ Update email template (copy HTML above)
3. ✅ Save template
4. 🧪 Test with real email
5. 🎉 Done!

---

## 📞 Quick Links

- **Your Template:** https://dashboard.emailjs.com/admin/templates/nauz08m
- **Your Service:** https://dashboard.emailjs.com/admin/services/service_54jp6ru
- **Dashboard:** https://dashboard.emailjs.com/
- **Logs:** https://dashboard.emailjs.com/admin/logs

---

## 🚀 Ready to Test!

```bash
flutter pub get
flutter run
```

Then register with your real email and check your inbox! 📧

Good luck! 🎉
