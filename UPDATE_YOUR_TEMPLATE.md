# 📧 Update Your EmailJS Template - Step by Step

## 🎯 Current Status

I can see your template is already created! Now let's make it beautiful.

---

## 📝 Step-by-Step Instructions

### Step 1: Open Your Template

You're already there! I can see you're on:
```
https://dashboard.emailjs.com/admin/templates/nauz08m
```

### Step 2: Click "Edit Content"

Look for the "Edit Content" button (✏️ icon) on the right side of the "Content" section.

### Step 3: Update the Subject

**Current Subject:**
```
OTP for your {Company Name} authentication
```

**Change to:**
```
Meal Manager - Your OTP Code
```

### Step 4: Update the Email Body

1. Click on the **Desktop** tab (if not already selected)
2. You'll see the HTML editor
3. **Delete ALL the current content**
4. Open the file: `COPY_THIS_TEMPLATE.html`
5. **Copy EVERYTHING** from that file
6. **Paste** into the EmailJS editor

### Step 5: Verify Template Variables

Make sure these variables are present in your template:
- `{{to_name}}` - User's name
- `{{to_email}}` - User's email (auto-filled)
- `{{otp_code}}` - The OTP code

### Step 6: Save Template

Click the **"Save"** button (top right, blue button)

---

## 🧪 Test Your Template

### Option 1: Test in EmailJS Dashboard

1. Click **"Test It"** button (top right)
2. Fill in test values:
   ```
   to_name: John Doe
   to_email: your-email@gmail.com
   otp_code: 123456
   ```
3. Click **"Send Test"**
4. Check your email inbox (including spam folder)

### Option 2: Test in Flutter App

```bash
flutter run
```

Then:
1. Click "Register" tab
2. Fill form with YOUR real email
3. Click "Sign Up"
4. Check your email inbox
5. Enter OTP from email
6. Click "Verify"
7. Success! ✅

---

## 📧 What the Email Will Look Like

```
┌─────────────────────────────────────────────┐
│                                             │
│         🍽️ Meal Manager                     │
│                                             │
└─────────────────────────────────────────────┘

Hello John Doe!

Welcome to Meal Manager. Your OTP for 
registration is:

┌─────────────────────────────────────────────┐
│                                             │
│              1 2 3 4 5 6                    │
│                                             │
└─────────────────────────────────────────────┘

⏰ This OTP is valid for 10 minutes.

If you didn't request this, please ignore 
this email.

─────────────────────────────────────────────
Meal Manager
Manage Meals, Deposits & Expenses Smartly
📧 MealManagerApps@gmail.com
```

---

## ✅ Checklist

- [ ] Opened template in EmailJS
- [ ] Clicked "Edit Content"
- [ ] Updated subject to "Meal Manager - Your OTP Code"
- [ ] Copied HTML from COPY_THIS_TEMPLATE.html
- [ ] Pasted in EmailJS editor
- [ ] Verified variables: {{to_name}}, {{to_email}}, {{otp_code}}
- [ ] Clicked "Save"
- [ ] Sent test email
- [ ] Received test email
- [ ] Tested in Flutter app
- [ ] Received real OTP email
- [ ] Verified OTP successfully

---

## 🔍 Troubleshooting

### Problem: Can't find "Edit Content"
**Solution:** Look for the ✏️ pencil icon next to "Content" section

### Problem: Template variables not showing
**Solution:** 
- Make sure you use double curly braces: `{{variable}}`
- Variable names must match exactly: `to_name`, `to_email`, `otp_code`

### Problem: Email looks broken
**Solution:**
- Make sure you copied the ENTIRE HTML from COPY_THIS_TEMPLATE.html
- Don't modify the HTML unless you know CSS
- Re-paste and save again

### Problem: Test email not received
**Solution:**
- Check spam/junk folder
- Wait 1-2 minutes
- Verify your email address is correct
- Check EmailJS dashboard logs

---

## 📊 Current Settings I Can See

From your screenshot:

✅ **Template Name:** One-Time Password
✅ **Template ID:** template_nauz08m
✅ **From Name:** Mealmanager
✅ **Reply To:** alphammo61@gmail.com
✅ **To Email:** {{email}}

**Note:** Change `{{email}}` to `{{to_email}}` to match our code!

---

## 🎯 Quick Fix for "To Email"

I noticed in your screenshot it shows `{{email}}` but our code sends `{{to_email}}`.

**Fix this:**
1. In the right panel, find "To Email" field
2. Change from: `{{email}}`
3. Change to: `{{to_email}}`
4. Click "Save"

---

## 🚀 Ready to Test!

Once you've updated the template:

```bash
# Run the app
flutter run

# Register with real email
# Check inbox
# Enter OTP
# Success! 🎉
```

---

## 📞 Quick Links

- **Your Template:** https://dashboard.emailjs.com/admin/templates/nauz08m
- **Dashboard:** https://dashboard.emailjs.com/
- **Logs:** https://dashboard.emailjs.com/admin/logs
- **HTML Template:** COPY_THIS_TEMPLATE.html

---

## ✨ Summary

1. ✅ Your credentials are configured
2. ⏳ Update template content (copy from COPY_THIS_TEMPLATE.html)
3. ⏳ Change "To Email" from {{email}} to {{to_email}}
4. ⏳ Save template
5. 🧪 Test!
6. 🎉 Done!

You're almost there! Just copy the HTML and save! 🚀
