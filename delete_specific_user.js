/**
 * Delete Specific User Script
 * 
 * This script deletes a specific user by email:
 * 1. Firebase Authentication user
 * 2. Firestore user document
 * 3. Related OTP data
 * 
 * Usage: node delete_specific_user.js asifmollik93@gmail.com
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
  admin.initializeApp({
    projectId: 'mealmanager-6a053'
  });
} catch (error) {
  console.error('Failed to initialize Firebase Admin:', error.message);
  console.log('\nPlease run: firebase login');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

async function deleteUserByEmail(email) {
  console.log(`\n🔥 Deleting user: ${email}\n`);
  
  try {
    // Step 1: Get user by email from Authentication
    let user;
    try {
      user = await auth.getUserByEmail(email);
      console.log(`✓ Found auth user: ${user.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('⚠️  User not found in Firebase Authentication');
      } else {
        throw error;
      }
    }
    
    // Step 2: Delete from Firebase Authentication
    if (user) {
      await auth.deleteUser(user.uid);
      console.log('✓ Deleted from Firebase Authentication');
      
      // Step 3: Delete Firestore user document
      try {
        await db.collection('users').doc(user.uid).delete();
        console.log('✓ Deleted Firestore user document');
      } catch (error) {
        console.log('⚠️  No Firestore user document found');
      }
    }
    
    // Step 4: Delete OTP data
    try {
      await db.collection('emailOtps').doc(email.toLowerCase().trim()).delete();
      console.log('✓ Deleted OTP data');
    } catch (error) {
      console.log('⚠️  No OTP data found');
    }
    
    // Step 5: Check deleted_users collection
    try {
      const deletedUserQuery = await db.collection('deleted_users')
        .where('email', '==', email.toLowerCase())
        .get();
      
      if (!deletedUserQuery.empty) {
        for (const doc of deletedUserQuery.docs) {
          await doc.ref.delete();
          console.log('✓ Deleted from deleted_users collection');
        }
      }
    } catch (error) {
      console.log('⚠️  No deleted_users record found');
    }
    
    console.log('\n✅ User deletion complete!\n');
    console.log('You can now create a new account with this email.\n');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

// Get email from command line argument
const email = process.argv[2];

if (!email) {
  console.error('\n❌ Error: Please provide an email address');
  console.log('\nUsage: node delete_specific_user.js <email>\n');
  console.log('Example: node delete_specific_user.js asifmollik93@gmail.com\n');
  process.exit(1);
}

// Run the script
deleteUserByEmail(email)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
