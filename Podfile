source 'https://cdn.cocoapods.org/'

platform :ios, '13.0'
use_frameworks!

workspace 'ParseLiveQuery.xcworkspace'
project 'sources/ParseLiveQuery.xcodeproj'

VERSION_TMGParseCore      = '1.19.7'
VERSION_Starscream        = '4.0.4'
VERSION_BoltsSwift        = '1.5.0'



target 'ParseLiveQuery-iOS' do
	pod 'TMGParseCore', VERSION_TMGParseCore
	pod 'Starscream', VERSION_Starscream
	pod 'Bolts-Swift', VERSION_BoltsSwift
end

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