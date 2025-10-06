#!/bin/bash

# Deploy Firestore Security Rules
# This script deploys the Firestore security rules to Firebase

echo "🚀 Deploying Firestore Security Rules..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Set the Firebase project
echo "📋 Setting Firebase project to msbridge-9a2c7..."
firebase use msbridge-9a2c7

# Deploy only the Firestore rules
echo "🔒 Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo "✅ Firestore rules deployment complete!"
echo "🌐 Project Console: https://console.firebase.google.com/project/msbridge-9a2c7/overview"
