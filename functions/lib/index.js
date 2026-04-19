"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupExpiredDeletedMesses = exports.cleanupInactiveMesses = exports.cleanupMessOperationalData = exports.cleanupEphemeralData = exports.restoreMess = exports.softDeleteMess = exports.updateLastActivity = exports.onUserDeleted = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_2 = require("firebase-admin/firestore");
(0, app_1.initializeApp)();
/**
 * Triggered when an admin deletes a user document from Firestore.
 * Automatically deletes the corresponding Firebase Auth account.
 */
exports.onUserDeleted = (0, firestore_1.onDocumentDeleted)('users/{userId}', async (event) => {
    const userId = event.params.userId;
    const deletedData = event.data?.data();
    const email = deletedData?.['email'] ?? '';
    const auth = (0, auth_1.getAuth)();
    const db = (0, firestore_2.getFirestore)();
    // 1. Delete from Firebase Auth
    try {
        await auth.deleteUser(userId);
        console.log(`Auth account deleted for uid: ${userId}`);
    }
    catch (err) {
        // User may not exist in Auth (e.g. manually created Firestore doc)
        console.warn(`Could not delete Auth user ${userId}:`, err.message);
    }
    // 2. Record in deleted_users so re-registration is blocked
    if (email) {
        try {
            await db.collection('deleted_users').doc(userId).set({
                email: email.toLowerCase(),
                deletedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            console.log(`Recorded deleted email: ${email}`);
        }
        catch (err) {
            console.warn('Could not record deleted_users:', err.message);
        }
    }
});
// ---------------------------------------------------------------------------
// Stubs — implemented in subsequent tasks
// ---------------------------------------------------------------------------
// Triggers
var updateLastActivity_1 = require("./triggers/updateLastActivity");
Object.defineProperty(exports, "updateLastActivity", { enumerable: true, get: function () { return updateLastActivity_1.updateLastActivity; } });
// Callables
var softDeleteMess_1 = require("./callable/softDeleteMess");
Object.defineProperty(exports, "softDeleteMess", { enumerable: true, get: function () { return softDeleteMess_1.softDeleteMess; } });
var restoreMess_1 = require("./callable/restoreMess");
Object.defineProperty(exports, "restoreMess", { enumerable: true, get: function () { return restoreMess_1.restoreMess; } });
// Scheduled cleanup jobs
var cleanupEphemeralData_1 = require("./cleanup/cleanupEphemeralData");
Object.defineProperty(exports, "cleanupEphemeralData", { enumerable: true, get: function () { return cleanupEphemeralData_1.cleanupEphemeralData; } });
var cleanupMessOperationalData_1 = require("./cleanup/cleanupMessOperationalData");
Object.defineProperty(exports, "cleanupMessOperationalData", { enumerable: true, get: function () { return cleanupMessOperationalData_1.cleanupMessOperationalData; } });
var cleanupInactiveMesses_1 = require("./cleanup/cleanupInactiveMesses");
Object.defineProperty(exports, "cleanupInactiveMesses", { enumerable: true, get: function () { return cleanupInactiveMesses_1.cleanupInactiveMesses; } });
var cleanupExpiredDeletedMesses_1 = require("./cleanup/cleanupExpiredDeletedMesses");
Object.defineProperty(exports, "cleanupExpiredDeletedMesses", { enumerable: true, get: function () { return cleanupExpiredDeletedMesses_1.cleanupExpiredDeletedMesses; } });
//# sourceMappingURL=index.js.map