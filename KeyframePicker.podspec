Pod::Spec.new do |s|
  s.name         = "KeyframePicker"
  s.version      = "1.0.1"
  s.summary      = "Keyframe image generateor and picker from a video like iPhone photo library written in Swift."
  s.homepage     = "https://github.com/zzltjnh/KeyframePicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "zzltjnh" => "zzltjnh@gmail.com" }
  s.source       = { :git => "https://github.com/zzltjnh/KeyframePicker.git", :tag => "#{s.version}" }

  s.ios.deployment_target = '8.0'

  s.source_files  = "source/**/*.swift"

  s.resources = "source/**/*.storyboard", "Resources/images.xcassets"

end
