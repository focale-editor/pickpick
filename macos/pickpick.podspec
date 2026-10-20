Pod::Spec.new do |s|
  s.name             = 'pickpick'
  s.version          = '0.1.0'
  s.summary          = 'Pick screen colors through the system color sampler.'
  s.description      = 'A consent-driven Flutter screen color picker using NSColorSampler on macOS.'
  s.homepage         = 'https://github.com/focale-editor/pickpick'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Hugo Delaunay'
  s.source           = { :path => '.' }
  s.source_files     = 'pickpick/Sources/pickpick/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.frameworks       = 'AppKit'
  s.platform         = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'
end
