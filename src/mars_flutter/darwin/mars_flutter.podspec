#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mars_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mars_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'mars_flutter/Sources/mars_flutter/**/*'
  s.swift_version = '5.0'

  s.ios.deployment_target = '15.0'
  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.ios.dependency 'Flutter'

  s.osx.deployment_target = '12.0'
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.osx.dependency 'FlutterMacOS'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mars_flutter_privacy' => ['mars_flutter/Sources/mars_flutter/PrivacyInfo.xcprivacy']}
end
