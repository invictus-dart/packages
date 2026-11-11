import 'package:code_assets/code_assets.dart';

/// Apple frameworks linked on iOS/macOS.
List<String> get frameworks => [
  'SystemConfiguration',
  'CoreTelephony',
  'Foundation',
];

/// Platform system libraries linked into the mars dynamic library.
List<String> getSystemLibraries(OS targetOS) => switch (targetOS) {
  .android => ['c++_shared', 'log', 'z'],
  .iOS || .macOS => ['c++', 'resolv', 'z'],
  .windows => [
    'ws2_32',
    'iphlpapi',
    'winhttp',
    'wininet',
    'advapi32',
    'crypt32',
    'user32',
    'gdi32',
    'runtimeobject',
  ],
  .linux => ['stdc++', 'z', 'pthread', 'dl'],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// OpenSSL library names per platform (import-library names on Windows).
List<String> getOpensslLibraries(OS targetOS) => switch (targetOS) {
  .android || .iOS || .macOS || .linux => ['crypto', 'ssl'],
  .windows => ['libcrypto', 'libssl'],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// Zstd library names per platform.
///
/// On unix the CMake static target installs as libzstd.a (`-lzstd`). On
/// Windows zstd renames the MSVC static archive to zstd_static.lib
/// (build/cmake/lib/CMakeLists.txt L196-200) to avoid clashing with the
/// shared import library zstd.lib.
List<String> getZstdLibraries(OS targetOS) => switch (targetOS) {
  .android || .iOS || .macOS || .linux => ['zstd'],
  .windows => ['zstd_static'],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};
