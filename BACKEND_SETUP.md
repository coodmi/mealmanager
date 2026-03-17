# Backend Setup for Email OTP

## Current Status
The app is currently using **DEMO MODE** which prints OTP to console. To send real emails, you need to set up a backend.

## Option 1: Node.js Backend (Recommended)

### 1. Create a simple Node.js server

```bash
mkdir meal-manager-backend
cd meal-manager-backend
npm init -y
npm install express nodemailer cors dotenv
```

### 2. Create `server.js`:

```javascript
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Email transporter setup (using Gmail)
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // Your Gmail
    pass: process.env.EMAIL_PASS  // App Password
  }
});

// Send OTP endpoint
app.post('/send-otp', async (req, res) => {
  const { email, otp, name } = req.body;

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Meal Manager - OTP Verification',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2 style="color: #177C60;">Meal Manager</h2>
        <p>Hello ${name},</p>
        <p>Your OTP for registration is:</p>
        <h1 style="color: #11835B; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
        <p>This OTP is valid for 10 minutes.</p>
        <p>If you didn't request this, please ignore this email.</p>
        <hr>
        <p style="color: #7F8C8D; font-size: 12px;">
          Meal Manager - Manage Meals, Deposits & Expenses Smartly
        </p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({ success: false, message: 'Failed to send OTP' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### 3. Create `.env` file:

```
EMAIL_USER=MealManagerApps@gmail.com
EMAIL_PASS=your_app_password_here
PORT=3000
```

### 4. Get Gmail App Password:
1. Go to Google Account settings
2. Enable 2-Step Verification
3. Go to App Passwords
4. Generate password for "Mail"
5. Copy and paste in `.env`

### 5. Run the server:

```bash
node server.js
```

### 6. Update Flutter app:

In `lib/core/services/email_service.dart`, replace:
```dart
Uri.parse('YOUR_BACKEND_API_URL/send-otp')
```
with:
```dart
Uri.parse('http://localhost:3000/send-otp')  // For testing
// or
Uri.parse('https://your-domain.com/send-otp')  // For production
```

## Option 2: Firebase Cloud Functions

### 1. Install Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

### 2. Create function in `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');
admin.initializeApp();

const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass
  }
});

exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email, otp, name } = data;

  const mailOptions = {
    from: functions.config().email.user,
    to: email,
    subject: 'Meal Manager - OTP Verification',
    html: `
      <h2>Hello ${name},</h2>
      <p>Your OTP is: <strong>${otp}</strong></p>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: 'OTP sent' };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### 3. Set config:
```bash
firebase functions:config:set email.user="MealManagerApps@gmail.com"
firebase functions:config:set email.pass="your_app_password"
```

### 4. Deploy:
```bash
firebase deploy --only functions
```

## Option 3: Third-Party Email Services

### SendGrid
```dart
// Add to pubspec.yaml
sendgrid_mailer: ^0.2.0

// Use in code
import 'package:sendgrid_mailer/sendgrid_mailer.dart';

final mailer = Mailer('YOUR_SENDGRID_API_KEY');
final toAddress = Address('user@example.com');
final fromAddress = Address('MealManagerApps@gmail.com');
final content = Content('text/html', '<h1>OTP: $otp</h1>');
final subject = 'Your OTP';
final email = Email([Personalization([toAddress])], fromAddress, subject, content: [content]);

await mailer.send(email);
```

### Mailgun
```dart
// Similar setup with Mailgun API
```

## Current Demo Mode

The app currently uses `sendOTPEmailDemo()` which:
- Prints OTP to console
- Shows OTP in SnackBar (for testing)
- Stores OTP in SharedPreferences
- Works without any backend

## To Switch to Real Email:

In `lib/core/services/auth_service.dart`, change:
```dart
final result = await EmailService.sendOTPEmailDemo(
```
to:
```dart
final result = await EmailService.sendOTPEmail(
```

## Testing

1. Register with your email
2. Check console for OTP (Demo mode)
3. Check email inbox (Real mode)
4. Enter OTP in verification screen
5. Should redirect to login on success

## Security Notes

- Never commit API keys to Git
- Use environment variables
- Implement rate limiting
- Add OTP expiry (10 minutes)
- Hash passwords before storing
- Use HTTPS in production
- Validate email format server-side

## Production Checklist

- [ ] Set up proper backend
- [ ] Configure email service
- [ ] Add rate limiting
- [ ] Implement OTP expiry
- [ ] Remove OTP from response
- [ ] Add proper error handling
- [ ] Set up monitoring
- [ ] Configure CORS properly
- [ ] Use environment variables
- [ ] Deploy to production server
