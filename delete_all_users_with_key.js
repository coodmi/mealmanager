/**
 * Delete All Firebase Authentication Users
 * 
 * Prerequisites:
 * 1. Download service account key from Firebase Console
 * 2. Save as 'service-account-key.json' in project root
 * 3. Run: npm install firebase-admin (if not already installed)
 * 4. Run: node delete_all_users_with_key.js
 */

const admin = require('firebase-admin');
const readline = require('readline');
const fs = require('fs');

// Check if service account key exists
if (!fs.existsSync('./service-account-key.json')) {
  console.error('\n❌ Error: service-account-key.json not found!\n');
  console.log('Please download your service account key:');
  console.log('1. Go to: https://console.firebase.google.com/project/mealmanager-6a053/settings/serviceaccounts/adminsdk');
  console.log('2. Click "Generate new private key"');
  console.log('3. Save as "service-account-key.json" in the project root\n');
  process.exit(1);
}

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function deleteAllAuthUsers() {
  console.log('\n🔥 Deleting Firebase Authentication users...\n');
  
  let deletedCount = 0;
  let errorCount = 0;
  let pageToken;
  
  try {
    do {
      const listUsersResult = await auth.listUsers(1000, pageToken);
      
      console.log(`   Found ${listUsersResult.users.length} users in this batch...`);
      
      for (const user of listUsersResult.users) {
        try {
          await auth.deleteUser(user.uid);
          deletedCount++;
          console.log(`   ✓ [${deletedCount}] Deleted: ${user.email || user.phoneNumber || user.uid}`);
        } catch (error) {
          errorCount++;
          console.error(`   ✗ Failed to delete ${user.uid}:`, error.message);
        }
      }
      
      pageToken = listUsersResult.pageToken;
    } while (pageToken);
    
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║              ✅ DELETION COMPLETE                      ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    console.log(`\n✅ Successfully deleted: ${deletedCount} users`);
    if (errorCount > 0) {
      console.log(`❌ Failed to delete: ${errorCount} users`);
    }
    console.log('');
    
    return { deletedCount, errorCount };
  } catch (error) {
    console.error('\n❌ Error listing users:', error.message);
    return { deletedCount, errorCount };
  }
}

async function main() {
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║    DELETE ALL AUTHENTICATION USERS - CONFIRMATION      ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('\n⚠️  WARNING: This will permanently delete:');
  console.log('   • All Firebase Authentication users');
  console.log('   • User login credentials');
  console.log('   • OAuth connections');
  console.log('\n🚨 THIS ACTION CANNOT BE UNDONE!');
  console.log('\n📝 Note: Firestore data should be deleted separately\n');
  
  rl.question('Type "DELETE ALL AUTH USERS" to confirm: ', async (answer) => {
    if (answer === 'DELETE ALL AUTH USERS') {
      console.log('\n🚀 Starting deletion process...');
      
      try {
        const result = await deleteAllAuthUsers();
        
        if (result.deletedCount === 0 && result.errorCount === 0) {
          console.log('ℹ️  No users found to delete.\n');
        }
        
      } catch (error) {
        console.error('\n❌ Error during deletion:', error);
      }
    } else {
      console.log('\n❌ Deletion cancelled. You must type "DELETE ALL AUTH USERS" exactly.\n');
    }
    
    rl.close();
    process.exit(0);
  });
}

// Run the script
main().catch(console.error);
