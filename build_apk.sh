#!/usr/bin/env bash
# ── Build a shareable release APK for Sangam (macOS/Linux) ──
# Firebase keys below are client-side Android keys (safe to embed).
set -e

flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=AIzaSyD2XrdYAZS7lIWlS1KfvVAuguIPVRNoR9c \
  --dart-define=FIREBASE_APP_ID=1:479664821501:android:42b5145c0fb5e644c95a94 \
  --dart-define=FIREBASE_SENDER_ID=479664821501 \
  --dart-define=FIREBASE_PROJECT_ID=sangam-649f5 \
  --dart-define=FIREBASE_STORAGE_BUCKET=sangam-649f5.firebasestorage.app

echo ""
echo "============================================================"
echo " APK ready to share:"
echo " build/app/outputs/flutter-apk/app-release.apk"
echo "============================================================"
