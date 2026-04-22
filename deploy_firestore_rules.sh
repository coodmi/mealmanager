#!/bin/bash

# Deploy Firestore security rules
echo "Deploying Firestore security rules..."
firebase deploy --only firestore:rules

echo "Done! Firestore rules updated."
