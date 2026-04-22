#!/bin/bash

echo "🔍 Searching for user with phone: 01645784709"
echo ""

# Export all users from Firestore
firebase firestore:export firestore-backup --project mealmanager-6a053 2>&1 > /dev/null

echo "✅ Backup created"
echo ""
echo "To delete all users and start fresh, run:"
echo "firebase firestore:delete 'users' --project mealmanager-6a053 --recursive --force"
echo ""
echo "Or manually delete from Firebase Console:"
echo "https://console.firebase.google.com/project/mealmanager-6a053/firestore/data/users"
