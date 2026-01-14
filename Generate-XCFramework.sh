#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

WORKSPACE="ParseLiveQuery.xcworkspace"
CONFIG="Release"
XC_NAME="TMGParseLiveQuery"

BUILD_DIR="$SCRIPT_DIR/.build-xcframework"
ARCHIVES_DIR="$BUILD_DIR/archives"

IOS_ARCHIVE="$ARCHIVES_DIR/ios"
SIM_ARCHIVE="$ARCHIVES_DIR/ios-sim"

ZIP_OUT="$SCRIPT_DIR/$XC_NAME.zip"

rm -rf "$BUILD_DIR" "$ZIP_OUT"
mkdir -p "$ARCHIVES_DIR"

# ---- Detect scheme ----
SCHEMES_JSON="$(xcodebuild -list -json -workspace "$WORKSPACE" 2>/dev/null)"
if echo "$SCHEMES_JSON" | grep -q '"Pods_ParseLiveQuery_iOS"'; then
  SCHEME="Pods_ParseLiveQuery_iOS"
elif echo "$SCHEMES_JSON" | grep -q '"ParseLiveQuery-iOS"'; then
  SCHEME="ParseLiveQuery-iOS"
else
  echo "❌ Could not find ParseLiveQuery scheme"
  exit 1
fi

echo "Using scheme: $SCHEME"

# ---- Build device ----
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "generic/platform=iOS" \
  -archivePath "$IOS_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# ---- Build simulator ----
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

IOS_FW="$(find "$IOS_ARCHIVE.xcarchive/Products/Library/Frameworks" -name '*.framework' | head -n 1)"
SIM_FW="$(find "$SIM_ARCHIVE.xcarchive/Products/Library/Frameworks" -name '*.framework' | head -n 1)"

[[ -d "$IOS_FW" && -d "$SIM_FW" ]] || { echo "❌ Frameworks not found"; exit 1; }

# ---- Create XCFramework (temp) ----
xcodebuild -create-xcframework \
  -framework "$IOS_FW" \
  -framework "$SIM_FW" \
  -output "$BUILD_DIR/$XC_NAME.xcframework"

# ---- Zip only ----
ditto -c -k --sequesterRsrc --keepParent \
  "$BUILD_DIR/$XC_NAME.xcframework" \
  "$ZIP_OUT"

# ---- Cleanup everything else ----
rm -rf "$BUILD_DIR"

echo "✅ Done"
echo "Final artifact:"
echo "  $ZIP_OUT"
