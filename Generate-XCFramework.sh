#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT="Sources/ParseLiveQuery.xcodeproj"
SCHEME="ParseLiveQuery-iOS"
TEST_SCHEME="TMGParseLiveQueryTests"
CONFIG="Release"
XC_NAME="TMGParseLiveQuery"

BUILD_DIR="$SCRIPT_DIR/.build-xcframework"
ARCHIVES_DIR="$BUILD_DIR/archives"

IOS_ARCHIVE="$ARCHIVES_DIR/ios"
SIM_ARCHIVE="$ARCHIVES_DIR/ios-sim"

ZIP_OUT="$SCRIPT_DIR/$XC_NAME.zip"

rm -rf "$BUILD_DIR" "$ZIP_OUT"
mkdir -p "$ARCHIVES_DIR"

# ---- Run unit tests first (fail-fast: no xcframework if tests fail) ----
# Tests run in the scheme's default (Debug) config — Release disables ENABLE_TESTABILITY,
# which would break `@testable import`. Set SKIP_TESTS=1 to bypass, or TEST_DESTINATION to override.
if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  TEST_DEST="${TEST_DESTINATION:-}"
  if [[ -z "$TEST_DEST" ]]; then
    # Warm up CoreSimulator: on a cold service the first `xcodebuild -showdestinations` lists only
    # the "Any iOS Simulator Device" placeholder (concrete sims not yet enumerated), which we filter
    # out below — causing a spurious "no destination" failure that disappears on a second run.
    xcrun simctl list devices available >/dev/null 2>&1 || true

    # Ask xcodebuild for destinations it will actually accept for this scheme (simctl can list sims
    # from other runtimes that xcodebuild won't target). Retry while only the placeholder is present,
    # to ride out the warm-up race on the first invocation. Capture stderr+exit status separately so a
    # genuine failure (bad scheme, missing SDK) is reported as itself, not as "no simulator".
    RAW=""; DESTS=""
    for _ in 1 2 3 4 5; do
      if ! RAW="$(xcodebuild -showdestinations -project "$PROJECT" -scheme "$TEST_SCHEME" 2>&1)"; then
        echo "❌ xcodebuild -showdestinations failed for scheme $TEST_SCHEME:" >&2
        echo "$RAW" >&2
        exit 1
      fi
      DESTS="$(echo "$RAW" | grep 'platform:iOS Simulator' | grep -v placeholder || true)"
      [[ -n "$DESTS" ]] && break
      sleep 2
    done
    SIM_ID="$(echo "$DESTS" | grep -m1 'iPhone' | grep -oE 'id:[0-9A-Fa-f-]{36}' | cut -d: -f2 || true)"
    [[ -n "$SIM_ID" ]] || SIM_ID="$(echo "$DESTS" | grep -m1 -oE 'id:[0-9A-Fa-f-]{36}' | cut -d: -f2 || true)"
    [[ -n "$SIM_ID" ]] || { echo "❌ No iOS Simulator destination for $TEST_SCHEME (command succeeded but listed no concrete simulator; set TEST_DESTINATION to override)"; exit 1; }
    TEST_DEST="platform=iOS Simulator,id=$SIM_ID"
  fi
  echo "Running tests ($TEST_SCHEME) on: $TEST_DEST"
  RESULT_BUNDLE="$BUILD_DIR/TestResults.xcresult"
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$TEST_SCHEME" \
    -destination "$TEST_DEST" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE"
  # Capture a coverage summary now (the result bundle is cleaned up with BUILD_DIR later).
  COVERAGE_REPORT="$(xcrun xccov view --report --only-targets "$RESULT_BUNDLE" 2>/dev/null || true)"
fi

echo "Building $XC_NAME from $PROJECT (scheme: $SCHEME)"

# ---- Build device ----
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "generic/platform=iOS" \
  -archivePath "$IOS_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# ---- Build simulator ----
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

IOS_FW="$(find "$IOS_ARCHIVE.xcarchive/Products/Library/Frameworks" -name "$XC_NAME.framework" | head -n 1)"
SIM_FW="$(find "$SIM_ARCHIVE.xcarchive/Products/Library/Frameworks" -name "$XC_NAME.framework" | head -n 1)"

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

if [[ -n "${COVERAGE_REPORT:-}" ]]; then
  echo
  echo "Test coverage (by target):"
  echo "$COVERAGE_REPORT"
fi
