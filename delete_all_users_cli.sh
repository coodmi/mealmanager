#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║         DELETE ALL USERS - CONFIRMATION REQUIRED       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This will permanently delete:"
echo "   • All Firebase Authentication users"
echo "   • All Firestore user documents"
echo "   • All messes and related data"
echo "   • All transactions, meals, expenses"
echo "   • All OTPs and logs"
echo ""
echo "🚨 THIS ACTION CANNOT BE UNDONE!"
echo ""
read -p "Type 'DELETE ALL USERS' to confirm: " confirmation

if [ "$confirmation" = "DELETE ALL USERS" ]; then
    echo ""
    echo "🚀 Starting deletion process..."
    echo ""
    
    # Delete all Firestore data
    echo "🔥 Deleting Firestore collections..."
    firebase firestore:delete --all-collections -f
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║              ✅ FIRESTORE DATA DELETED                 ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "⚠️  Note: Firebase Authentication users must be deleted manually"
    echo "   from the Firebase Console:"
    echo "   https://console.firebase.google.com/project/mealmanager-6a053/authentication/users"
    echo ""
    echo "   Or use the Firebase Admin SDK script."
    echo ""
else
    echo ""
    echo "❌ Deletion cancelled."
    echo ""
fi
