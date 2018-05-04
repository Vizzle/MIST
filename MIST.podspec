#
#  Be sure to run `pod spec lint MIST.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|


  s.name         = "MIST"
  s.version      = "0.0.4"
  s.summary      = "A High Performance Dynamic Template Engine."
  s.description  = "Dynamic View Template Engine Powered by Flexlayout"
  s.homepage      = "https://github.com/Vizzle/MIST"
  s.license       = "MIT"
  s.author        = { "vizlabxt" => "jayson.xu@foxmail.com" }
  s.source        = { :git => "https://github.com/Vizzle/MIST.git", :tag => s.version.to_s }
  s.source_files  = "MIST/**/*.{h,m,mm}"
  s.frameworks    = 'UIKit','ImageIO'
  s.ios.deployment_target = '8.0'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.library = 'c++'
  s.dependency "VZFlexLayout"

end
