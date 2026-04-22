/**
 * Check OTP from Firestore
 * 
 * Usage: node check_otp.js <email>
 * Example: node check_otp.js test@example.com
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
  admin.initializeApp({
    projectId: 'mealmanager-6a053'
  });
} catch (error) {
  console.error('Failed to initialize Firebase Admin:', error.message);
  process.exit(1);
}

const db = admin.firestore();

async function checkOTP(email) {
  try {
    const doc = await db.collection('emailOtps').doc(email.toLowerCase().trim()).get();
    
    if (!doc.exists) {
      console.log(`\n❌ No OTP found for: ${email}`);
      console.log('   Please try registering again.\n');
      return;
    }
    
    const data = doc.data();
    const otp = data.otp;
    const expiresAt = data.expiresAt.toDate();
    const verified = data.verified;
    const now = new Date();
    
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║                    OTP INFORMATION                     ║');
    console.log('╚════════════════════════════════════════════════════════╝\n');
    console.log(`📧 Email: ${email}`);
    console.log(`🔢 OTP: ${otp}`);
    console.log(`⏰ Expires: ${expiresAt.toLocaleString()}`);
    console.log(`✅ Verified: ${verified ? 'Yes' : 'No'}`);
    console.log(`⏳ Status: ${now > expiresAt ? 'EXPIRED' : 'VALID'}`);
    console.log('');
    
    if (verified) {
      console.log('⚠️  This OTP has already been used.\n');
    } else if (now > expiresAt) {
      console.log('⚠️  This OTP has expired. Please request a new one.\n');
    } else {
      console.log('✅ You can use this OTP to verify your account!\n');
    }
    
  } catch (error) {
    console.error('\n❌ Error:', error.message, '\n');
  }
  
  process.exit(0);
}

// Get email from command line
const email = process.argv[2];

if (!email) {
  console.log('\n❌ Please provide an email address');
  console.log('Usage: node check_otp.js <email>');
  console.log('Example: node check_otp.js test@example.com\n');
  process.exit(1);
}

checkOTP(email);
