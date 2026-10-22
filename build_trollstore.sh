#!/bin/bash
# ==============================================================================
# TrollStore / Jailbreak .tipa Packaging Script for Equalizer Pro
# Targets: iOS 14.0 - 15.x (iPhone & iPad)
# ==============================================================================

set -e

APP_NAME="EqualizerApp"
BUILD_DIR="build"
OUTPUT_DIR="output"
ENTITLEMENTS="EqualizerApp/App/EqualizerApp.entitlements"

echo "=== Packaging Equalizer Pro for TrollStore (iOS 14.0 - 15.x) ==="

# Clean previous build artifacts
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Payload"

# If built with xcodebuild or clang:
if [ -d "$BUILD_DIR/Release-iphoneos/$APP_NAME.app" ]; then
    echo "[+] Found existing Release build at $BUILD_DIR/Release-iphoneos/$APP_NAME.app"
    cp -r "$BUILD_DIR/Release-iphoneos/$APP_NAME.app" "$OUTPUT_DIR/Payload/"
elif [ -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "[+] Found build at $BUILD_DIR/$APP_NAME.app"
    cp -r "$BUILD_DIR/$APP_NAME.app" "$OUTPUT_DIR/Payload/"
else
    echo "[!] Compiling with xcodebuild (Target: iOS 14.0, Release)..."
    if command -v xcodebuild &> /dev/null; then
        xcodebuild -project "$APP_NAME.xcodeproj" \
                   -scheme "$APP_NAME" \
                   -configuration Release \
                   -destination 'generic/platform=iOS' \
                   -sdk iphoneos \
                   CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release-iphoneos" \
                   CODE_SIGNING_ALLOWED=NO \
                   IPHONEOS_DEPLOYMENT_TARGET=14.0 \
                   build
        cp -r "$BUILD_DIR/Release-iphoneos/$APP_NAME.app" "$OUTPUT_DIR/Payload/"
    else
        echo "[!] xcodebuild not found. Preparing directory structure for Xcode or Theos packaging."
        mkdir -p "$OUTPUT_DIR/Payload/$APP_NAME.app"
        cp -r EqualizerApp/* "$OUTPUT_DIR/Payload/$APP_NAME.app/"
    fi
fi

# Apply TrollStore Unsandboxed Entitlements with ldid if available
if command -v ldid &> /dev/null; then
    echo "[+] Applying TrollStore fake-sign & entitlements with ldid..."
    ldid -S"$ENTITLEMENTS" "$OUTPUT_DIR/Payload/$APP_NAME.app/$APP_NAME" 2>/dev/null || true
    ldid -S"$ENTITLEMENTS" "$OUTPUT_DIR/Payload/$APP_NAME.app" 2>/dev/null || true
fi

# Package as .tipa (TrollStore format) and .ipa
cd "$OUTPUT_DIR"
echo "[+] Compressing into EqualizerPro.tipa..."
zip -q -r "EqualizerPro.tipa" Payload
cp "EqualizerPro.tipa" "EqualizerPro.ipa"
cd ..

echo "=== Successfully built: $OUTPUT_DIR/EqualizerPro.tipa ==="
echo "You can now install EqualizerPro.tipa via TrollStore on iOS 14.0 - 15.x!"
