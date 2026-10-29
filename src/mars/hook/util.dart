import 'package:code_assets/code_assets.dart';

List<String> get frameworks => ['Foundation', 'SystemConfiguration'];

List<String> getSystemLibraries(OS targetOS) => switch (targetOS) {
  .android => ['c++_shared', 'log', 'z'],
  .iOS || .macOS => ['c++', 'z', 'pthread', 'dl'],
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
  .linux => ['stdc++', 'z', 'pthread', 'dl'],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

List<String> getOpensslLibraries(OS targetOS) => switch (targetOS) {
  .android || .iOS || .macOS || .linux => ['crypto', 'ssl'],
  .windows => ['libcrypto', 'libssl'],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

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
