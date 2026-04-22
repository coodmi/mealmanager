# Registration Test Checklist

## ✅ Pre-Test Verification

### Database Status
- ✅ Firestore: All data deleted (123 documents)
- ✅ Authentication: All users deleted
- ✅ Fresh start ready

### Code Fixes Applied
- ✅ Firestore security rules updated (allow public read for duplicate checks)
- ✅ Timeouts added to all Firestore queries (10 seconds)
- ✅ Timeout added to email service (10 seconds)
- ✅ Error handling improved with user-friendly messages
- ✅ Flutter dependencies refreshed

### Files Modified
1. ✅ `firestore.rules` - Security rules deployed
2. ✅ `lib/features/auth/presentation/pages/login_page.dart` - Timeouts added
3. ✅ `lib/core/services/email_service.dart` - Timeout added

## 🧪 Test Scenarios

### Test 1: New User Registration (Happy Path)

**Steps:**
1. Open app in Chrome
2. Go to "Register" tab
3. Fill in form:
   - Name: Test User
   - Mobile: 01712345678
   - Email: testuser@example.com
   - Password: Test123456
4. Check "I agree to Terms & Conditions"
5. Click "Sign Up"

**Expected Results:**
- ✅ Loading shows for 2-15 seconds (not infinite)
- ✅ OTP dialog appears
- ✅ Email received with 6-digit OTP
- ✅ Enter OTP successfully
- ✅ Account created message shown
- ✅ Redirected to login tab
- ✅ Can login with new credentials

**Status:** ⏳ Ready to test

---

### Test 2: Duplicate Email Detection

**Steps:**
1. Register first user (email: test1@example.com)
2. Try to register again with same email

**Expected Results:**
- ✅ Shows error: "Email already registered"
- ✅ No infinite loading
- ✅ Error appears within 10 seconds

**Status:** ⏳ Ready to test

---

### Test 3: Duplicate Phone Detection

**Steps:**
1. Register first user (phone: 01712345678)
2. Try to register again with same phone

**Expected Results:**
- ✅ Shows error: "Phone number already registered"
- ✅ No infinite loading
- ✅ Error appears within 10 seconds

**Status:** ⏳ Ready to test

---

### Test 4: OTP Verification

**Steps:**
1. Start registration
2. Wait for OTP dialog
3. Enter correct OTP from email

**Expected Results:**
- ✅ OTP dialog appears within 15 seconds
- ✅ Can enter 6-digit OTP
- ✅ Auto-submits after 6th digit
- ✅ Account created successfully
- ✅ Success message shown

**Status:** ⏳ Ready to test

---

### Test 5: OTP Resend

**Steps:**
1. Start registration
2. Wait for OTP dialog
3. Click "Resend OTP"

**Expected Results:**
- ✅ New OTP sent
- ✅ Success message shown
- ✅ Can verify with new OTP
- ✅ Old OTP becomes invalid

**Status:** ⏳ Ready to test

---

### Test 6: Invalid OTP

**Steps:**
1. Start registration
2. Wait for OTP dialog
3. Enter wrong OTP (e.g., 000000)

**Expected Results:**
- ✅ Shows error: "Incorrect OTP"
- ✅ Can try again
- ✅ Can resend OTP

**Status:** ⏳ Ready to test

---

### Test 7: Expired OTP

**Steps:**
1. Start registration
2. Wait for OTP dialog
3. Wait 11 minutes (OTP expires after 10 minutes)
4. Try to verify

**Expected Results:**
- ✅ Shows error: "OTP expired"
- ✅ Can resend new OTP
- ✅ New OTP works

**Status:** ⏳ Ready to test

---

### Test 8: Network Timeout Handling

**Steps:**
1. Disconnect internet briefly
2. Try to register
3. Reconnect internet

**Expected Results:**
- ✅ Shows timeout error within 10 seconds
- ✅ User-friendly error message
- ✅ Can retry registration
- ✅ Works after reconnection

**Status:** ⏳ Ready to test

---

### Test 9: Terms & Conditions Validation

**Steps:**
1. Fill registration form
2. Don't check "I agree to Terms"
3. Click "Sign Up"

**Expected Results:**
- ✅ Shows error: "Please agree to Terms & Conditions"
- ✅ Orange warning message
- ✅ Registration doesn't proceed

**Status:** ⏳ Ready to test

---

### Test 10: Form Validation

**Steps:**
1. Try to register with:
   - Empty name
   - Invalid phone (less than 11 digits)
   - Invalid email (no @)
   - Short password (less than 6 chars)

**Expected Results:**
- ✅ Shows validation errors
- ✅ "Required" for empty fields
- ✅ "Must be 11 digits" for phone
- ✅ "Invalid email" for email
- ✅ "Minimum 6 characters" for password

**Status:** ⏳ Ready to test

---

## 🚀 How to Run Tests

### Start the App
```bash
flutter run -d chrome
```

### Test Registration
1. Go to Register tab
2. Fill in the form
3. Click Sign Up
4. Verify OTP
5. Check success

### Monitor Console
- Check browser console for errors
- Check Flutter console for logs
- Verify no timeout errors

## ✅ Success Criteria

All tests should pass with:
- ✅ No infinite loading
- ✅ Clear error messages
- ✅ OTP dialog appears within 15 seconds
- ✅ Account created successfully
- ✅ Can login after registration
- ✅ Duplicate detection works
- ✅ Timeout handling works

## 🐛 If Issues Occur

### Infinite Loading
1. Check browser console for errors
2. Verify Firestore rules are deployed
3. Check internet connection
4. Restart app

### OTP Not Received
1. Check spam folder
2. Use "Resend OTP"
3. Check Firestore `emailOtps` collection
4. Verify EmailJS service status

### Duplicate Error When Shouldn't
1. Check Firestore `users` collection
2. Verify email/phone format
3. Clear Firestore data if needed

## 📊 Test Results

| Test | Status | Notes |
|------|--------|-------|
| New User Registration | ⏳ Pending | |
| Duplicate Email | ⏳ Pending | |
| Duplicate Phone | ⏳ Pending | |
| OTP Verification | ⏳ Pending | |
| OTP Resend | ⏳ Pending | |
| Invalid OTP | ⏳ Pending | |
| Expired OTP | ⏳ Pending | |
| Network Timeout | ⏳ Pending | |
| Terms Validation | ⏳ Pending | |
| Form Validation | ⏳ Pending | |

## 🎯 Quick Test (2 minutes)

**Minimal test to verify registration works:**

1. Run app: `flutter run -d chrome`
2. Go to Register tab
3. Fill form with unique email
4. Check Terms checkbox
5. Click Sign Up
6. Wait for OTP dialog (should appear in 5-15 seconds)
7. Enter OTP from email
8. Verify account created
9. Login with new account

**Expected**: ✅ All steps complete successfully

---

## 📝 Notes

- All Firestore data is cleared
- All authentication users are deleted
- Security rules are updated and deployed
- Timeouts are in place
- Error handling is improved
- App is ready for testing

## 🎉 Ready to Test!

Everything is set up and ready. Just run the app and try creating a new account!

```bash
flutter run -d chrome
```

Then follow Test 1 (New User Registration) above.

---

**Date**: April 21, 2026  
**Status**: ✅ Ready for testing  
**All fixes applied**: Yes  
**Database cleared**: Yes
