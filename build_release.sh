#!/bin/bash
echo "============================================================"
echo " SmartIoT v1.0.2 — Release Build Script"
echo " Developer: Sobuj Billah / Smart IoT Interface"
echo "============================================================"
echo ""

echo "[1/4] Cleaning previous builds..."
flutter clean

echo "[2/4] Getting dependencies..."
flutter pub get

echo "[3/4] Building Release APK..."
flutter build apk --release

echo "[4/4] Building Release AAB (Play Store)..."
flutter build appbundle --release

echo "============================================================"
echo " BUILD COMPLETE!"
echo " APK:  build/app/outputs/flutter-apk/app-release.apk"
echo " AAB:  build/app/outputs/bundle/release/app-release.aab"
echo "============================================================"
echo ""
echo "IMPORTANT: lib/firebase_options.dart-এর উপরের কমেন্টে Release SHA-1/SHA-256 আছে"
echo "Firebase Console → Project Settings → Android App-এ যোগ করুন (Google Sign-In কাজ করার জন্য)"
