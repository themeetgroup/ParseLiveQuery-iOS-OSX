#!/bin/bash

./build-dependencies.sh

rm -rf "${BUILD_DIR}"
START_DIR=$(pwd)

BUILD_DIR="${START_DIR}/build"
FRAMEWORKS_DIR="${BUILD_DIR}/Frameworks"
DERIVED_DATA="${BUILD_DIR}/DerivedData"

build_archive () {

    DESTINATION=$1
    PLATFORM=$2

    OUTPUT="${FRAMEWORKS_DIR}/${PLATFORM}"
    mkdir -p "${OUTPUT}"
    ARCHIVE_PATH="${OUTPUT}/Release-${PLATFORM}.xcarchive"

    xcodebuild archive \
        -destination "${DESTINATION}" \
        -scheme "ParseLiveQuery-iOS" \
        -archivePath "${ARCHIVE_PATH}" \
        -derivedDataPath "${DERIVED_DATA}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

    # Copy Generated framework
    GENERATED_FRAMEWORK_PATH="${ARCHIVE_PATH}/Products/Library/Frameworks/TMGParseLiveQuery.framework"
    FINAL_FRAMEWORK_PATH="${OUTPUT}/TMGParseLiveQuery.framework"
    mv ${GENERATED_FRAMEWORK_PATH} ${FINAL_FRAMEWORK_PATH}
}

build_archive "generic/platform=iOS" "iphoneos"
build_archive "generic/platform=iOS Simulator" "iphonesimulator"
xcodebuild -create-xcframework \
    -framework "${FRAMEWORKS_DIR}/iphoneos/TMGParseLiveQuery.framework" \
    -framework "${FRAMEWORKS_DIR}/iphonesimulator/TMGParseLiveQuery.framework" \
    -output "${BUILD_DIR}/TMGParseLiveQuery.xcframework"

cd "${START_DIR}"
rm -rf "Frameworks/TMGParseLiveQuery.xcframework"
mv "${BUILD_DIR}/TMGParseLiveQuery.xcframework" "Frameworks"
rm -rf "${BUILD_DIR}"
