#!/bin/bash

echo "🔍 Checking for user: asifmollik93@gmail.com"
echo ""

# Check emailOtps collection
echo "1️⃣ Checking emailOtps collection..."
firebase firestore:get "emailOtps/asifmollik93@gmail.com" --project mealmanager-6a053 2>&1 | grep -q "No document" && echo "   ✓ No OTP data found" || echo "   ⚠️  OTP data exists"

echo ""
echo "2️⃣ Checking Firebase Authentication..."
firebase auth:export temp_users.json --project mealmanager-6a053 2>&1 > /dev/null
if grep -q "asifmollik93@gmail.com" temp_users.json 2>/dev/null; then
    echo "   ⚠️  User exists in Authentication"
else
    echo "   ✓ No user in Authentication"
fi
rm -f temp_users.json

echo ""
echo "✅ User check complete!"
echo ""
echo "If all checks show ✓, you can create a new account with this email."
