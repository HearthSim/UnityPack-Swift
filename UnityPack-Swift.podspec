Pod::Spec.new do |s|
  s.name             = 'UnityPack-Swift'
  s.version          = '0.0.1'
  s.license          = 'MIT'
  s.summary          = 'UnityPack from Hearthstone'
  s.homepage         = 'https://github.com/HearthSim/UnityPack-Swift'
  s.authors          = { 'Benjamin Michotte' => 'bmichotte@gmail.com', 'Istvan Fehervari' => 'gooksl@gmail.com' }
  s.source           = { :git => 'https://github.com/HearthSim/UnityPack-Swift.git' }

  s.platform = :osx
  s.deployment_target = '10.10'
  s.framework = 'Foundation'

  s.source_files = 'Sources/**/*.swift'
  s.requires_arc = true
end
