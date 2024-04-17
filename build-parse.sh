#!/bin/bash

rm -rf "Parse-SDK-iOS-OSX"

START_DIR=$(pwd)
REPO="https://github.com/parse-community/Parse-SDK-iOS-OSX.git"
TAG=$1

BUILD_DIR="${START_DIR}/Parse-SDK-iOS-OSX/build"
FRAMEWORKS_DIR="${BUILD_DIR}/Frameworks"
FINAL_DIR="${START_DIR}/Frameworks"
DERIVED_DATA="${BUILD_DIR}/DerivedData"

git clone ${REPO}
cd "Parse-SDK-iOS-OSX"
git checkout ${TAG}

# To pull in extra dependencies (Bolts and OCMock)
git submodule update --init --recursive

################################################
########## Begin Framework Renaming ############
################################################
RETURN_DIR=$(pwd)
# Rename all occurances of <Parse/ to <ParseCore/
cd "Parse"
find . \( ! -regex '.*/\..*' \) -type f | LC_ALL=C xargs sed -i '' 's;<Parse/;<ParseCore/;g'

# Rename all occurances of Parse.framework to ParseCore.framework
find . \( ! -regex '.*/\..*' \) -type f | LC_ALL=C xargs sed -i '' 's;Parse.framework;ParseCore.framework;g'

# Rename all PRODUCT_NAME from Parse to ParseCore
cd "Configurations"
find . \( ! -regex '.*/\..*' \) -type f | LC_ALL=C xargs sed -i '' 's;PRODUCT_NAME = Parse;PRODUCT_NAME = ParseCore;g'
cd "${RETURN_DIR}"

# Rename Parse to ParseCore in the info.plist
cd "Parse/Parse/Resources/"
sed -i -e 's/Parse/ParseCore/g' Parse-iOS.info.plist
cd "${RETURN_DIR}"

# Copy the framework header
cp "${START_DIR}/Parse/ParseCore.h" "Parse/Parse/ParseCore.h"

# Setup gems needed to modify the XCode project
cat > Gemfile << EOF
source "https://rubygems.org"
ruby '2.7.7'
gem 'xcodeproj'
EOF

cat > .ruby-version << EOF
2.7.7
EOF

rbenv install -s
rbenv exec gem install 'bundler:2.3.22'
bundle check || bundle install

# Run the ruby script
cp -r "${START_DIR}/Frameworks/Bolts.xcframework" "Parse/Bolts.xcframework"
cp "${START_DIR}/Parse/Project.rb" "Project.rb"
ruby Project.rb

################################################
########## End Framework Renaming ##############
################################################

build_archive () {

    DESTINATION=$1
    PLATFORM=$2

    OUTPUT="${FRAMEWORKS_DIR}/${PLATFORM}"
    mkdir -p "${OUTPUT}"
    ARCHIVE_PATH="${OUTPUT}/Release-${PLATFORM}.xcarchive"

    xcodebuild archive \
        -destination "${DESTINATION}" \
        -scheme "Parse-iOS" \
        -archivePath "${ARCHIVE_PATH}" \
        -derivedDataPath "${DERIVED_DATA}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

    # Copy Generated framework
    GENERATED_FRAMEWORK_PATH="${ARCHIVE_PATH}/Products/@rpath/ParseCore.framework"
    FINAL_FRAMEWORK_PATH="${OUTPUT}/ParseCore.framework"
    mv ${GENERATED_FRAMEWORK_PATH} ${FINAL_FRAMEWORK_PATH}
}

build_archive "generic/platform=iOS" "iphoneos"
build_archive "generic/platform=iOS Simulator" "iphonesimulator"
xcodebuild -create-xcframework \
    -framework "${FRAMEWORKS_DIR}/iphoneos/ParseCore.framework" \
    -framework "${FRAMEWORKS_DIR}/iphonesimulator/ParseCore.framework" \
    -output "${FINAL_DIR}/ParseCore.xcframework"

cd "${START_DIR}"
 rm -rf "Parse-SDK-iOS-OSX"
