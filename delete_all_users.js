/**
 * Delete All Users Script
 * 
 * This script deletes:
 * 1. All Firebase Authentication users
 * 2. All Firestore user documents
 * 3. All related data (messes, members, etc.)
 * 
 * WARNING: This is irreversible!
 * 
 * Usage: node delete_all_users.js
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin with application default credentials
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

// Create readline interface for confirmation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function deleteAllAuthUsers() {
  console.log('\n🔥 Deleting Firebase Authentication users...');
  
  let deletedCount = 0;
  let pageToken;
  
  try {
    do {
      const listUsersResult = await auth.listUsers(1000, pageToken);
      
      for (const user of listUsersResult.users) {
        try {
          await auth.deleteUser(user.uid);
          deletedCount++;
          console.log(`   ✓ Deleted auth user: ${user.email || user.uid}`);
        } catch (error) {
          console.error(`   ✗ Failed to delete ${user.uid}:`, error.message);
        }
      }
      
      pageToken = listUsersResult.pageToken;
    } while (pageToken);
    
    console.log(`\n✅ Deleted ${deletedCount} authentication users`);
    return deletedCount;
  } catch (error) {
    console.error('Error listing users:', error.message);
    return deletedCount;
  }
}

async function deleteCollection(collectionPath, batchSize = 100) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.limit(batchSize);
  
  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();
    
    if (snapshot.size === 0) {
      resolve();
      return;
    }
    
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    // Recurse on the next process tick
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

async function deleteSubcollections() {
  console.log('\n🔥 Deleting mess subcollections...');
  
  try {
    const messesSnapshot = await db.collection('messes').get();
    
    for (const messDoc of messesSnapshot.docs) {
      const messId = messDoc.id;
      console.log(`   Deleting subcollections for mess: ${messId}`);
      
      const subcollections = [
        'members',
        'transactions',
        'meals',
        'expenses',
        'withdrawals',
        'monthSummaries',
        'joinRequests'
      ];
      
      for (const subcollection of subcollections) {
        try {
          await deleteCollection(`messes/${messId}/${subcollection}`);
          console.log(`      ✓ Deleted ${subcollection}`);
        } catch (error) {
          console.error(`      ✗ Failed to delete ${subcollection}:`, error.message);
        }
      }
    }
    
    console.log('\n✅ Deleted all subcollections');
  } catch (error) {
    console.error('Error deleting subcollections:', error.message);
  }
}

async function deleteAllFirestoreData() {
  console.log('\n🔥 Deleting Firestore data...');
  
  const collections = [
    'users',
    'messes',
    'emailOtps',
    'deleted_users',
    'deleted_messes',
    'admins',
    'systemLogs'
  ];
  
  for (const collection of collections) {
    try {
      console.log(`   Deleting ${collection}...`);
      await deleteCollection(collection);
      console.log(`   ✓ Deleted ${collection}`);
    } catch (error) {
      console.error(`   ✗ Failed to delete ${collection}:`, error.message);
    }
  }
  
  console.log('\n✅ Deleted all Firestore collections');
}

async function main() {
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║         DELETE ALL USERS - CONFIRMATION REQUIRED       ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('\n⚠️  WARNING: This will permanently delete:');
  console.log('   • All Firebase Authentication users');
  console.log('   • All Firestore user documents');
  console.log('   • All messes and related data');
  console.log('   • All transactions, meals, expenses');
  console.log('   • All OTPs and logs');
  console.log('\n🚨 THIS ACTION CANNOT BE UNDONE!\n');
  
  rl.question('Type "DELETE ALL USERS" to confirm: ', async (answer) => {
    if (answer === 'DELETE ALL USERS') {
      console.log('\n🚀 Starting deletion process...\n');
      
      try {
        // Step 1: Delete subcollections first
        await deleteSubcollections();
        
        // Step 2: Delete Firestore data
        await deleteAllFirestoreData();
        
        // Step 3: Delete Authentication users
        await deleteAllAuthUsers();
        
        console.log('\n╔════════════════════════════════════════════════════════╗');
        console.log('║              ✅ DELETION COMPLETE                      ║');
        console.log('╚════════════════════════════════════════════════════════╝');
        console.log('\nAll users and data have been permanently deleted.\n');
        
      } catch (error) {
        console.error('\n❌ Error during deletion:', error);
      }
    } else {
      console.log('\n❌ Deletion cancelled. You must type "DELETE ALL USERS" exactly.\n');
    }
    
    rl.close();
    process.exit(0);
  });
}

// Run the script
main().catch(console.error);
