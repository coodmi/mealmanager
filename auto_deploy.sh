#!/bin/bash
# Auto Deploy to Firebase App Distribution
# Called automatically after code changes

echo "🚀 Auto-deploying to Firebase App Distribution..."
echo "📦 Building APK..."

flutter build apk --release

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo "☁️  Uploading to Firebase..."

firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:186008201235:android:5e3237690feab3c61537e6 \
  --release-notes "Auto-deploy: $(date '+%Y-%m-%d %H:%M')" \
  --testers "asifmollik93@gmail.com"

if [ $? -eq 0 ]; then
  echo "✅ Deployed successfully! Check asifmollik93@gmail.com for download link."
else
  echo "❌ Deploy failed!"
  exit 1
fi
