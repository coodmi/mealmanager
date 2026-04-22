# Delete Firebase Authentication Users

## ✅ Firestore Data Deleted

All Firestore collections have been successfully deleted:
- ✅ users
- ✅ messes
- ✅ members
- ✅ meals
- ✅ transactions
- ✅ expenses
- ✅ emailOtps
- ✅ All other collections

**Total deleted**: 123 documents

## 🔐 Delete Authentication Users

Firebase Authentication users need to be deleted separately. Here are your options:

### Option 1: Firebase Console (Easiest)

1. **Open Firebase Console**:
   https://console.firebase.google.com/project/mealmanager-6a053/authentication/users

2. **Select all users**:
   - Click the checkbox at the top to select all users
   - Or select users individually

3. **Delete**:
   - Click the "Delete" button (trash icon)
   - Confirm deletion

### Option 2: Firebase CLI (Bulk Delete)

Unfortunately, Firebase CLI doesn't have a direct command to delete all auth users. You need to use the Admin SDK.

### Option 3: Using Firebase Admin SDK (Automated)

Since the Admin SDK requires proper credentials, here's how to set it up:

#### Step 1: Download Service Account Key

1. Go to: https://console.firebase.google.com/project/mealmanager-6a053/settings/serviceaccounts/adminsdk
2. Click "Generate new private key"
3. Save the JSON file as `service-account-key.json` in the project root

#### Step 2: Run the deletion script

```bash
# Install dependencies
npm install firebase-admin

# Run the script
node delete_all_users_with_key.js
```

### Option 4: Manual Deletion (If few users)

If you have only a few users, manually delete them from the Firebase Console:

1. Go to Authentication > Users
2. Click on each user
3. Click "Delete user"
4. Confirm

## Current Status

✅ **Firestore**: All data deleted (123 documents)  
⏳ **Authentication**: Needs manual deletion from console

## Quick Links

- **Firebase Console**: https://console.firebase.google.com/project/mealmanager-6a053
- **Authentication Users**: https://console.firebase.google.com/project/mealmanager-6a053/authentication/users
- **Firestore Database**: https://console.firebase.google.com/project/mealmanager-6a053/firestore

## Verification

After deleting auth users, verify:

1. **Authentication**: No users listed
2. **Firestore**: No documents in any collection
3. **App**: Registration works for new users

## Notes

- Firestore data is already deleted ✅
- Authentication users persist independently
- Deleting auth users doesn't affect Firestore (already done)
- New users can register immediately after deletion

---

**Recommendation**: Use Option 1 (Firebase Console) for the quickest and safest deletion of authentication users.
