#!/bin/bash

DIRECTORY=$1
SCHEME=$2
PRODUCT_NAME=$3
POD=$4
VERSION=$5
PROJECT_PATH=$(pwd)

mkdir -p "${DIRECTORY}"
cd "${DIRECTORY}"
mkdir -p "fastlane"
cd "fastlane"

cat > Fastfile << EOF
fastlane_version "2.35.0"
default_platform :ios
platform :ios do
  desc "Export the XCFramework"
  lane :xcframework do |options|
    create_xcframework(scheme: "${SCHEME}",
        product_name: "${PRODUCT_NAME}",
        workspace: 'TMGPods.xcworkspace',
        include_dSYMs: true,
        include_BCSymbolMaps: false,
        include_bitcode: false,
        destinations: ["iOS"],
        xcframework_output_directory: "./Frameworks")
  end
end
EOF

cd ../

mkdir -p "TMGPods.xcworkspace"
xcodebuild -workspace "TMGPods.xcworkspace"

cat > Podfile << EOF
source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'
use_frameworks!
workspace 'TMGPods'
pod "${POD}", "${VERSION}"

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Fix warnings related to multiple dependencies having a deployment version < 12.0,
      # which is now the minimum Xcode supports
      if Gem::Version.new('12.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end

EOF

cat > Gemfile << EOF
source "https://rubygems.org"
ruby '2.7.7'
gem 'fastlane'
gem 'cocoapods', '1.13.0'
gem 'fastlane-plugin-create_xcframework'
gem 'activesupport', '~> 7.0.8'
EOF

cat > .ruby-version << EOF
2.7.7
EOF

rbenv install -s

# Check if Bundler 2.3.22 needs to be installed
if [ -z "$(gem list | grep bundler | grep -E '2\.3\.22')" ]; then
echo "Installing Bundler 2.3.22"
rbenv exec gem install 'bundler:2.3.22'
else
echo "Bundler 2.3.22 already installed"
fi

bundle check || bundle install
bundle exec pod install

bundle exec fastlane ios xcframework
mv "./Frameworks/${PRODUCT_NAME}.xcframework" "${PROJECT_PATH}/Frameworks"

cd $PROJECT_PATH
rm -rf ${DIRECTORY}
