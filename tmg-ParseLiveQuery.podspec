Pod::Spec.new do |s|
  s.name             = 'tmg-ParseLiveQuery'
  s.version          = '2.8.7'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Allows for subscriptions to queries in conjunction with parse-server.'
  s.homepage         = 'http://parseplatform.org'
  s.authors          = { 'Parse Community' => 'info@parseplatform.org', 'Richard Ross' => 'richardross@fb.com', 'Nikita Lutsenko' => 'nlutsenko@me.com', 'Florent Vilmart' => 'florent@flovilmart.com' }

  s.source       = { :git => 'https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.platform = :ios
  s.swift_version = '5.0'
  s.cocoapods_version = '>= 1.4'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/ParseLiveQuery/**/*.{swift,h}'
  s.module_name = 'TMGParseLiveQuery'

  s.dependency 'TMGParseCore', '1.19.7'
  s.dependency 'Bolts-Swift', '1.5.0'
  s.dependency 'Starscream', '4.0.4'

end
