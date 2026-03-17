# GitHub Actions CI/CD Setup Guide
## Meal Manager — Flutter App

---

## ধাপ ১: GitHub Repository তৈরি করো

```bash
# প্রজেক্ট ফোল্ডারে যাও
cd /Users/asifmollik/StudioProjects/mealmanager

# Git initialize করো
git init
git add .
git commit -m "Initial commit"

# GitHub-এ নতুন repo তৈরি করো (github.com → New Repository)
# তারপর:
git remote add origin https://github.com/YOUR_USERNAME/mealmanager.git
git branch -M main
git push -u origin main
```

---

## ধাপ ২: Android Keystore তৈরি করো (একবারই করতে হবে)

```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias mealmanager \
  -dname "CN=Meal Manager, OU=Dev, O=AlphaInno, L=Dhaka, S=Dhaka, C=BD"
```

পাসওয়ার্ড মনে রাখো — এটা পরে GitHub Secrets-এ দিতে হবে।

---

## ধাপ ৩: GitHub Secrets সেট করো

GitHub → তোমার Repo → Settings → Secrets and variables → Actions → New repository secret

### প্রয়োজনীয় Secrets:

| Secret Name | কীভাবে পাবে |
|---|---|
| `GOOGLE_SERVICES_JSON` | নিচের কমান্ড দিয়ে base64 করো |
| `KEYSTORE_BASE64` | নিচের কমান্ড দিয়ে base64 করো |
| `KEYSTORE_PASSWORD` | keystore তৈরির সময় দেওয়া পাসওয়ার্ড |
| `KEY_PASSWORD` | key-এর পাসওয়ার্ড (সাধারণত একই) |
| `KEY_ALIAS` | `mealmanager` |
| `FIREBASE_APP_ID_ANDROID` | Firebase Console থেকে |
| `FIREBASE_SERVICE_ACCOUNT` | নিচে দেখো |
| `FIREBASE_PROJECT_ID` | Firebase Console থেকে |

### Base64 কনভার্ট করার কমান্ড:

```bash
# google-services.json → base64
base64 -i android/app/google-services.json | pbcopy
# (clipboard-এ copy হয়ে যাবে, সরাসরি paste করো)

# keystore → base64
base64 -i android/app/keystore.jks | pbcopy
```

---

## ধাপ ৪: Firebase App Distribution সেটআপ

### 4.1 — Firebase Console-এ App Distribution চালু করো
1. [Firebase Console](https://console.firebase.google.com) → তোমার প্রজেক্ট
2. বাম মেনু → **App Distribution**
3. **Get started** ক্লিক করো
4. Android app select করো

### 4.2 — Firebase App ID খুঁজে বের করো
Firebase Console → Project Settings → General → তোমার Android App → **App ID**
(format: `1:123456789:android:abcdef123456`)

### 4.3 — Testers Group তৈরি করো
App Distribution → **Testers & Groups** → **Add group** → নাম দাও `testers`
→ ক্লায়েন্টদের email add করো

---

## ধাপ ৫: Firebase Service Account তৈরি করো

```
Firebase Console → Project Settings → Service Accounts
→ "Generate new private key" ক্লিক করো
→ JSON ফাইল download হবে
→ সেই JSON-এর পুরো content copy করো
→ GitHub Secret FIREBASE_SERVICE_ACCOUNT-এ paste করো
```

---

## ধাপ ৬: Firebase Hosting সেটআপ (Web এর জন্য)

```bash
# Firebase CLI install করো (যদি না থাকে)
npm install -g firebase-tools

# Login করো
firebase login

# প্রজেক্টে hosting init করো
firebase init hosting
# → "Use an existing project" select করো
# → public directory: build/web
# → Single-page app: Yes
# → GitHub Actions: Yes (যদি জিজ্ঞেস করে)
```

---

## CI/CD Flow কীভাবে কাজ করে

```
তুমি code push করো (main branch)
        ↓
GitHub Actions শুরু হয়
        ↓
┌─────────────────────────────────┐
│  Job 1: Test                    │
│  • flutter analyze              │
│  • flutter test                 │
└──────────────┬──────────────────┘
               ↓ (pass হলে)
┌──────────────┴──────────────────┐
│  Job 2: Android Build           │
│  • APK build (release)          │
│  • Firebase App Distribution    │
│  • ক্লায়েন্ট email পায়          │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  Job 3: Web Build               │
│  • flutter build web            │
│  • Firebase Hosting deploy      │
│  • Live URL আপডেট হয়           │
└─────────────────────────────────┘
```

---

## ক্লায়েন্ট কীভাবে আপডেট পাবে?

- **Android**: Firebase App Distribution থেকে email আসবে, link দিয়ে APK install করবে
- **Web**: তোমার Firebase Hosting URL সরাসরি আপডেট হয়ে যাবে

---

## সমস্যা হলে

```bash
# Workflow logs দেখো
GitHub → Actions → সেই workflow → logs

# Local-এ test করো
flutter build apk --release
flutter build web --release
```
