Pod::Spec.new do |s|
  s.name             = 'tmg-ParseLiveQuery'
  s.version          = '2.9.0'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Allows for subscriptions to queries in conjunction with parse-server.'
  s.homepage         = 'http://parseplatform.org'
  s.social_media_url = 'https://twitter.com/ParsePlatform'
  s.authors          = { 'Parse Community' => 'info@parseplatform.org', 'Richard Ross' => 'richardross@fb.com', 'Nikita Lutsenko' => 'nlutsenko@me.com', 'Florent Vilmart' => 'florent@flovilmart.com' }

  s.source       = { :git => 'https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX.git', :branch => "xcframework" }

  s.requires_arc = true

  s.platform = :ios
  s.swift_version = '5.0'

  s.deployment_target = '13.0'

  s.source_files = 'Sources/ParseLiveQuery/**/*.{swift,h}'
  s.module_name = 'TMGParseLiveQuery'

  s.vendored_framework = 'Frameworks/Bolts.xcframework',
                          'Frameworks/BoltsSwift.xcframework',
                          'Frameworks/ParseCore.xcframework',
                          'TMGParseLiveQuery.xcframework',
                          'Starscream.xcframework'

  s.preserve_path = 'Frameworks/*'

end