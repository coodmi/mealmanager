#!/bin/bash

echo "🔧 Fixing Flutter assets issue..."
echo ""

# Clean Flutter build cache
echo "1️⃣ Cleaning Flutter build cache..."
flutter clean

# Get dependencies
echo ""
echo "2️⃣ Getting Flutter dependencies..."
flutter pub get

# Build for web
echo ""
echo "3️⃣ Building for web..."
flutter build web --release

echo ""
echo "✅ Done! Now run: flutter run -d chrome"
