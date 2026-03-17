# 🔙 How to Go Back to Login Screen

## 🎯 You're Currently On: Dashboard Page

This is a placeholder screen that will be fully implemented later.

---

## 🔄 How to Get Back to Login/Register

### Method 1: Press Back Button (Easiest)
1. Press the **Back button** on your phone/emulator
2. Or press **ESC** key on your keyboard
3. Keep pressing until you see the Login/Register screen

### Method 2: Restart the App
1. In terminal, press `R` (capital R)
2. App will restart at Login screen

### Method 3: Stop and Restart
1. In terminal, press `q` (quit)
2. Run: `flutter run -d emulator-5554`
3. App starts fresh at Login screen

---

## 🧪 Proper Testing Flow

To test OTP properly:

1. **Start at Login/Register screen**
2. Click **"Register"** tab
3. Fill the form
4. Click **"Sign Up"**
5. See **popup with OTP**
6. Click **"Continue to Verification"**
7. Enter OTP
8. Click **"Verify"**
9. Success → Back to Login screen

**Don't click "Login" button yet** - that's for after you've registered!

---

## 📱 What You're Seeing

The Dashboard page shows:
- Ma Chatrabash (mess name)
- Today's Mess Meal counts
- Bazar Schedule
- Bottom navigation

This is a **preview** of what the app will look like after:
1. You register
2. Verify OTP
3. Login
4. Create or join a mess

---

## ✅ Quick Fix

**Just press the Back button** (or ESC key) until you see the Login/Register screen again.

Then test the OTP flow properly! 🚀

---

## 🎯 Summary

Current Screen: Dashboard (preview)
Need to Go: Login/Register screen
How: Press Back button or ESC key
Then: Test OTP registration flow
