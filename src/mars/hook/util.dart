import 'package:code_assets/code_assets.dart';

List<String> get frameworks => ['Foundation', 'SystemConfiguration'];

List<String> getSystemLibraries(OS targetOS) => switch (targetOS) {
  .android => ['log', 'z', 'c++_shared'],
  .iOS || .macOS => ['z', 'pthread', 'dl', 'c++'],
  .windows => [
    'ws2_32',
    'iphlpapi',
    'winhttp',
    'wininet',
    'advapi32',
    'crypt32',
    'user32',
    'gdi32',
    'shell32',
    'ole32',
    'runtimeobject',
  ],
  .linux => ['z', 'pthread', 'dl', 'stdc++'],
  _ => [],
};

List<String> getOpensslLibraries(OS targetOS) =>
    targetOS == .windows ? ['libcrypto', 'libssl'] : ['crypto', 'ssl'];

String getOpensslLibraryDirectory(
  Uri packageRoot,
  OS targetOS,
  Architecture targetArchitecture,
  IOSSdk? targetSdk,
) {
  final architectureName = switch (targetOS) {
    .android => switch (targetArchitecture) {
      .arm => 'armeabi-v7a',
      .arm64 => 'arm64-v8a',
      .ia32 => 'x86',
      .x64 => 'x86_64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $targetOS, $targetArchitecture',
      ),
    },
    .iOS => switch (targetArchitecture) {
      .arm64 => switch (targetSdk) {
        .iPhoneOS => 'arm64',
        .iPhoneSimulator => 'simulator_arm64',
        _ => throw UnsupportedError(
          'Unsupported iOS SDK: $targetOS, $targetArchitecture, $targetSdk',
        ),
      },
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $targetOS, $targetArchitecture',
      ),
    },
    .macOS => switch (targetArchitecture) {
      .arm64 => 'arm64',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $targetOS, $targetArchitecture',
      ),
    },
    .windows => switch (targetArchitecture) {
      .arm64 => 'arm64',
      .ia32 => 'x86',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $targetOS, $targetArchitecture',
      ),
    },
    .linux => switch (targetArchitecture) {
      .arm => 'arm32',
      .arm64 => 'arm64',
      .ia32 => 'x86',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $targetOS, $targetArchitecture',
      ),
    },
    _ => throw UnsupportedError('Unsupported os: $targetOS'),
  };
  return packageRoot
      .resolve('src/mars/openssl/openssl_lib_$targetOS/$architectureName/')
      .toFilePath();
}
