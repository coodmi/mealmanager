# Firebase Setup Guide for Meal Manager

## Why Firebase?
- ✅ **FREE** to start (Spark Plan)
- ✅ Real-time data sync across devices
- ✅ Built-in authentication
- ✅ Offline support
- ✅ Automatic scaling
- ✅ No server management needed

## Free Tier Limits (More than enough!)
- **Authentication**: 10,000 phone verifications/month
- **Firestore**: 1GB storage, 50K reads/day, 20K writes/day
- **Storage**: 5GB for images/files
- **Push Notifications**: Unlimited

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `meal-manager` or `mealmanager`
4. Disable Google Analytics (optional, can enable later)
5. Click "Create Project"

---

## Step 2: Add Android App

1. In Firebase Console, click Android icon
2. Enter package name: `com.example.mealmanager`
   - Find in: `android/app/build.gradle.kts` (applicationId)
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

---

## Step 3: Enable Authentication

1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable these sign-in methods:
   - ✅ Email/Password
   - ✅ Phone (optional, for OTP)

---

## Step 4: Create Firestore Database

1. In Firebase Console → Firestore Database
2. Click "Create Database"
3. Choose "Start in test mode" (for development)
4. Select location: `asia-south1` (Mumbai) or closest to Bangladesh
5. Click "Enable"

### Security Rules (for testing):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Step 5: Install Flutter Packages

Run these commands:

```bash
# Core Firebase
flutter pub add firebase_core

# Authentication
flutter pub add firebase_auth

# Database
flutter pub add cloud_firestore

# Storage (for images)
flutter pub add firebase_storage

# Push Notifications
flutter pub add firebase_messaging

# Optional: Analytics
flutter pub add firebase_analytics
```

---

## Step 6: Configure Android

### 6.1 Update `android/build.gradle.kts`:
Add this to dependencies block:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

### 6.2 Update `android/app/build.gradle.kts`:
Add at the bottom:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

---

## Step 7: Initialize Firebase in App

I'll create the initialization code for you!

---

## Database Structure for Meal Manager

```
users/
  {userId}/
    - name: string
    - email: string
    - mobile: string
    - messId: string
    - role: "manager" | "member"
    - createdAt: timestamp

messes/
  {messId}/
    - name: string
    - address: string
    - district: string
    - managerId: string
    - members: array
    - balance: number
    - createdAt: timestamp
    - subscription: "free" | "lite" | "plus" | "pro"

meals/
  {messId}/
    entries/
      {date}/
        {userId}/
          - breakfast: boolean
          - lunch: boolean
          - dinner: boolean
          - guestMeals: number

expenses/
  {messId}/
    entries/
      {expenseId}/
        - amount: number
        - category: string
        - description: string
        - addedBy: userId
        - date: timestamp
        - approved: boolean

deposits/
  {messId}/
    entries/
      {depositId}/
        - userId: string
        - amount: number
        - date: timestamp
        - method: string

withdrawals/
  {messId}/
    entries/
      {withdrawalId}/
        - userId: string
        - amount: number
        - status: "pending" | "approved" | "rejected"
        - date: timestamp
```

---

## Cost Estimation

### For 100 Active Users:
- **Reads**: ~5,000/day (well under 50K limit)
- **Writes**: ~2,000/day (well under 20K limit)
- **Storage**: ~100MB (well under 1GB limit)
- **Cost**: $0/month ✅ FREE

### When to Upgrade (Blaze Plan - Pay as you go):
- 500+ active users
- 100K+ reads/day
- Need Cloud Functions for complex logic
- Still very cheap: ~$5-25/month

---

## Alternative: Supabase (Also FREE)

If you prefer PostgreSQL over NoSQL:
- ✅ FREE tier: 500MB database, 1GB file storage
- ✅ Built-in authentication
- ✅ Real-time subscriptions
- ✅ RESTful API
- ✅ SQL queries (more familiar)

---

## Next Steps

1. Create Firebase project
2. Download `google-services.json`
3. Let me know when ready, I'll integrate it into the app!

---

## Questions?

- **Q: Will I be charged?**
  - A: No, unless you exceed free limits (very unlikely for your app)

- **Q: What happens if I exceed limits?**
  - A: Firebase will stop serving requests until next day OR you can upgrade

- **Q: Can I switch later?**
  - A: Yes, you can migrate to your own backend anytime

- **Q: Is my data safe?**
  - A: Yes, Firebase has enterprise-grade security and backups
