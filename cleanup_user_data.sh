#!/bin/bash

echo "🧹 Cleaning up data for: asifmollik93@gmail.com"
echo ""

# Delete OTP data
echo "Deleting OTP data..."
firebase firestore:delete "emailOtps/asifmollik93@gmail.com" --project mealmanager-6a053 --force

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "You can now create a new account with asifmollik93@gmail.com"
