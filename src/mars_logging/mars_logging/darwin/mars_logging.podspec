#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mars_logging.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mars_logging'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'mars_logging/Sources/mars_logging/**/*'
  s.frameworks = 'SystemConfiguration', 'CoreTelephony', 'Foundation'
  s.vendored_xcframeworks = 'Frameworks/mars.xcframework'
  s.libraries = 'resolv.9', 'z'
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mars_logging_privacy' => ['mars_logging/Sources/mars_logging/PrivacyInfo.xcprivacy']}

  s.ios.deployment_target = '15.0'
  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # 'SWIFT_OBJC_BRIDGING_HEADER' => '${PODS_TARGET_SRCROOT}/Classes/MarsLogging-Bridging-Header.h',
    # 'SWIFT_OBJC_INTEROP_MODE' => 'objcxx',
    # 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }
  s.ios.dependency 'Flutter'

  s.osx.deployment_target = '12.0'
  s.osx.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'MACOSX_DEPLOYMENT_TARGET' => '12.0',
  }
  s.osx.dependency 'FlutterMacOS'
end
