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

# Make subclass registering method public
cd "Parse/Parse/Internal/Object/Subclassing"
REPLACE_STRING="@interface PFObjectSubclassingController : NSObject"
PUBLIC_METHOD="- (void)_rawRegisterSubclass:(Class)kls;"
NEW_STRING="${REPLACE_STRING}\n${PUBLIC_METHOD}"
sed -i -e 's/'"${REPLACE_STRING}"'/'"${NEW_STRING}"'/g' PFObjectSubclassingController.h
cd "${RETURN_DIR}"

# Rename all occurances of _rawRegisterSubclass to rawRegisterSubclass
find . \( ! -regex '.*/\..*' \) -type f | LC_ALL=C xargs sed -i '' 's;_rawRegisterSubclass;rawRegisterSubclass;g'

# Make ParseManager accessible
cd "Parse/Parse"
FOUNDATION_STRING="#import <Foundation/Foundation.h>"
FOUNDATION_REPLACE_STRING="${FOUNDATION_STRING}\n#import <ParseCore/ParseManager.h>"
sed -i -e 's;'"${FOUNDATION_STRING}"';'"${FOUNDATION_REPLACE_STRING}"';g' Parse.h
INTERFACE_STRING="@interface Parse : NSObject"
INTERFACE_REPLACE_STRING="${INTERFACE_STRING}\n@property (nonatomic, nullable, readonly, class) ParseManager *currentManager;"
sed -i -e 's.'"${INTERFACE_STRING}"'.'"${INTERFACE_REPLACE_STRING}"'.g' Parse.h

IMP_STRING="@implementation Parse"
IMP_REPLACE_STRING="${IMP_STRING}\n+ (ParseManager *)currentManager {\nreturn currentParseManager_;\n}"
sed -i -e 's.'"${IMP_STRING}"'.'"${IMP_REPLACE_STRING}"'.g' Parse.m

cd "Internal"
INIT_STRING="+ (instancetype)new NS_UNAVAILABLE;"
INIT_REPLACE_STRING="${INIT_STRING}\n- (void)rawRegisterSubclass:(Class)kls;"
sed -i -e 's.'"${INIT_STRING}"'.'"${INIT_REPLACE_STRING}"'.g' PFCoreManager.h
IMP_STRING="@implementation PFCoreManager"
IMP_REPLACE_STRING="${IMP_STRING}\n- (void)rawRegisterSubclass:(Class)kls {\n[[self objectSubclassingController] _rawRegisterSubclass:kls];\n}"
sed -i -e 's.'"${IMP_STRING}"'.'"${IMP_REPLACE_STRING}"'.g' PFCoreManager.m

cd "${RETURN_DIR}"

# Rename Parse to ParseCore in the info.plist
cd "Parse/Parse/Resources/"
sed -i -e 's/Parse/ParseCore/g' Parse-iOS.info.plist
cd "${RETURN_DIR}"

# Create the needed framework header file
cd "Parse/Parse"
cat > ParseCore.h << EOF
#import <Foundation/Foundation.h>
#import <ParseCore/Parse.h>
#import <ParseCore/PFCoreManager.h>
#import <ParseCore/PFEventuallyPin.h>
#import <ParseCore/PFPin.h>
#import <ParseCore/ParseClientConfiguration.h>
#import <ParseCore/PFACL.h>
#import <ParseCore/PFAnalytics.h>
#import <ParseCore/PFAnonymousUtils.h>
#import <ParseCore/PFAnonymousUtils+Deprecated.h>
#import <ParseCore/PFCloud.h>
#import <ParseCore/PFCloud+Deprecated.h>
#import <ParseCore/PFCloud+Synchronous.h>
#import <ParseCore/PFConfig.h>
#import <ParseCore/PFConfig+Synchronous.h>
#import <ParseCore/PFConstants.h>
#import <ParseCore/PFDecoder.h>
#import <ParseCore/PFEncoder.h>
#import <ParseCore/PFFileObject.h>
#import <ParseCore/PFFileObject+Deprecated.h>
#import <ParseCore/PFFileObject+Synchronous.h>
#import <ParseCore/PFGeoPoint.h>
#import <ParseCore/PFPolygon.h>
#import <ParseCore/PFObject.h>
#import <ParseCore/PFObject+Subclass.h>
#import <ParseCore/PFObject+Synchronous.h>
#import <ParseCore/PFObject+Deprecated.h>
#import <ParseCore/PFQuery.h>
#import <ParseCore/PFQuery+Synchronous.h>
#import <ParseCore/PFQuery+Deprecated.h>
#import <ParseCore/PFRelation.h>
#import <ParseCore/PFRole.h>
#import <ParseCore/PFSession.h>
#import <ParseCore/PFSubclassing.h>
#import <ParseCore/PFUser.h>
#import <ParseCore/PFUser+Synchronous.h>
#import <ParseCore/PFUser+Deprecated.h>
#import <ParseCore/PFUserAuthenticationDelegate.h>
#import <ParseCore/PFFileUploadResult.h>
#import <ParseCore/PFFileUploadController.h>
#import <ParseCore/PFInstallation.h>
#import <ParseCore/PFNetworkActivityIndicatorManager.h>
#import <ParseCore/PFPush.h>
#import <ParseCore/PFPush+Synchronous.h>
#import <ParseCore/PFPush+Deprecated.h>
#import <ParseCore/PFProduct.h>
#import <ParseCore/PFPurchase.h>
FOUNDATION_EXPORT double ParseCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char ParseCoreVersionString[];
EOF
cd "${RETURN_DIR}"

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

cat > update.rb << EOF
require 'xcodeproj'
project = Xcodeproj::Project.open("Parse/Parse.xcodeproj")
project.targets.each do |target|
    if target.name == "Parse-iOS"
        group = project.main_group
        file_ref = group.new_reference("Parse/ParseCore.h")
        header = target.headers_build_phase.add_file_reference(file_ref)
        header.settings = { 'ATTRIBUTES' => ['Public'] }
        for i in 0..target.headers_build_phase.files.length - 1
            build_file = target.headers_build_phase.files[i]
            build_file.settings = { 'ATTRIBUTES' => ['Public']}
        end
        project.save
    end
end
EOF
ruby update.rb

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