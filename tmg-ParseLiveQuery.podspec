Pod::Spec.new do |s|
  s.name             = 'tmg-ParseLiveQuery'
  s.version          = '2.8.4'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Allows for subscriptions to queries in conjunction with parse-server.'
  s.homepage         = 'http://parseplatform.org'
  s.social_media_url = 'https://twitter.com/ParsePlatform'
  s.authors          = { 'Parse Community' => 'info@parseplatform.org', 'Richard Ross' => 'richardross@fb.com', 'Nikita Lutsenko' => 'nlutsenko@me.com', 'Florent Vilmart' => 'florent@flovilmart.com' }

  s.source       = { :git => 'https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX.git', :branch => "xcframework" }

  s.requires_arc = true

  s.platform = :ios, :osx, :tvos, :watchos
  s.swift_version = '5.0'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/ParseLiveQuery/**/*.{swift,h}'
  s.module_name = 'TMGParseLiveQuery'

  s.ios.vendored_framework = 'Frameworks/Bolts.xcframework',
                             'Frameworks/BoltsSwift.xcframework',
                             'Frameworks/ParseCore.xcframework',
                             'TMGParseLiveQuery.xcframework'

end