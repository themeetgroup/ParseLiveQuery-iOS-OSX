#!/bin/bash

START_DIR=$(pwd)
REPO=$1
TAG=$2
DIRECTORY=$3
SCHEME_NAME=$4
PRODUCT_NAME=$5

BUILD_DIR="${START_DIR}/${DIRECTORY}/build"
FRAMEWORKS_DIR="${BUILD_DIR}/Frameworks"
FINAL_DIR="${START_DIR}/Frameworks"
DERIVED_DATA="${BUILD_DIR}/DerivedData"

git clone ${REPO}
cd ${DIRECTORY}
git checkout ${TAG}

build_archive () {

    DESTINATION=$1
    PLATFORM=$2
    NAME=$3
    FRAMEWORK_NAME=$4

    OUTPUT="${FRAMEWORKS_DIR}/${PLATFORM}"
    mkdir -p "${OUTPUT}"
    ARCHIVE_PATH="${OUTPUT}/Release-${PLATFORM}.xcarchive"

    xcodebuild archive \
        -destination "${DESTINATION}" \
        -scheme "${NAME}" \
        -archivePath "${ARCHIVE_PATH}" \
        -derivedDataPath "${DERIVED_DATA}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

    # Copy Generated framework
    GENERATED_FRAMEWORK_PATH="${ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    FINAL_FRAMEWORK_PATH="${OUTPUT}/${FRAMEWORK_NAME}.framework"
    mv ${GENERATED_FRAMEWORK_PATH} ${FINAL_FRAMEWORK_PATH}
}

build_archive "generic/platform=iOS" "iphoneos" ${SCHEME_NAME} ${PRODUCT_NAME}
build_archive "generic/platform=iOS Simulator" "iphonesimulator" ${SCHEME_NAME} ${PRODUCT_NAME}

xcodebuild -create-xcframework \
    -framework "${FRAMEWORKS_DIR}/iphoneos/${PRODUCT_NAME}.framework" \
    -framework "${FRAMEWORKS_DIR}/iphonesimulator/${PRODUCT_NAME}.framework" \
    -output "${FINAL_DIR}/${SCHEME_NAME}.xcframework"

cd "${START_DIR}"
rm -rf ${DIRECTORY}
