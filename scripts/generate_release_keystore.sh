#!/bin/bash

set -e

KEYSTORE_PATH="android/app/release.keystore"
KEY_ALIAS="release"
KEYSTORE_PASSWORD="radio_sathi_release_2024"
KEY_PASSWORD="radio_sathi_release_2024"
VALIDITY=10000

echo "Generating release keystore..."

keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Radio Sathi, OU=Development, O=Radio Sathi, L=Unknown, ST=Unknown, C=US"

echo "Keystore generated at: $KEYSTORE_PATH"

echo ""
echo "=========================================="
echo "BASE64 ENCODED KEYSTORE:"
echo "=========================================="
BASE64_KEYSTORE=$(base64 -w 0 "$KEYSTORE_PATH")
echo "$BASE64_KEYSTORE"
echo ""
echo "=========================================="
echo "SECRETS CONFIGURATION:"
echo "=========================================="
echo ""
echo "Add these secrets to your GitHub repository:"
echo ""
echo "RELEASE_KEYSTORE:"
echo "$BASE64_KEYSTORE"
echo ""
echo "KEY_ALIAS: $KEY_ALIAS"
echo "KEYSTORE_PASSWORD: $KEYSTORE_PASSWORD"
echo "KEY_PASSWORD: $KEY_PASSWORD"
echo ""
echo "=========================================="
echo ""
echo "To get individual values, run:"
echo "  base64 -w 0 android/app/release.keystore  # For RELEASE_KEYSTORE"
echo ""
echo "Or to copy the keystore to clipboard:"
echo "  base64 -w 0 android/app/release.keystore | pbcopy  # macOS"
echo "  base64 -w 0 android/app/release.keystore | xclip  # Linux"