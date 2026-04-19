"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateLastActivity = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
// Stub — implemented in Task 3
exports.updateLastActivity = (0, firestore_1.onDocumentWritten)('messes/{messId}/{subcol}/{docId}', async (_event) => {
    // TODO: implement in Task 3
});
//# sourceMappingURL=updateLastActivity.js.map