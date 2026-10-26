// Link hook: links per-module static libraries with OpenSSL and platform
// system libraries into a single dynamic library (mars.dll / libmars.dylib /
// libmars.so).

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  await link(args, (input, output) async {
    final logger = Logger('mars-link')
      ..level = Level.ALL
      ..onRecord.listen((record) => stdout.writeln(record.message));

    final packageRoot = input.packageRoot.toFilePath();
    final marsRoot = '$packageRoot/src/mars';
    final codeConfig = input.config.code;
    final targetOS = codeConfig.targetOS;
    final targetArch = codeConfig.targetArchitecture;
    // iOS SDK (iPhoneOS device vs iPhoneSimulator) determines which vendored
    // OpenSSL slice to use: device arm64 vs simulator arm64.
    final iosSdk = targetOS == OS.iOS ? codeConfig.iOS.targetSdk : null;
    final isWindows = targetOS == OS.windows;

    // Resolve OpenSSL library directory from the vendored layout.
    final opensslIncludeDir = '$marsRoot/openssl/include';
    final opensslLibDir = _opensslLibDir(marsRoot, targetOS, targetArch,
        iosSdk: iosSdk);
    if (opensslLibDir == null || !Directory(opensslLibDir).existsSync()) {
      throw UnsupportedError(
        'OpenSSL libraries not found for $targetOS/${targetArch.name}. '
        'Expected at $opensslLibDir.\n'
        'Run tool/openssl_download.dart first, or copy libs to '
        'src/mars/openssl/openssl_lib_${osToDir(targetOS)}/<arch>/.',
      );
    }
    if (!Directory(opensslIncludeDir).existsSync()) {
      throw UnsupportedError(
        'OpenSSL headers not found at $opensslIncludeDir. '
        'Run tool/openssl_download.dart first, or copy headers to '
        'src/mars/openssl/include/.',
      );
    }

    final opensslLibs = isWindows
        ? const ['libcrypto', 'libssl']
        : const ['crypto', 'ssl'];

    final systemLibraries = <String>[];
    final linkFlags = <String>[];
    switch (targetOS) {
      case OS.windows:
        systemLibraries.addAll([
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
        ]);
        linkFlags.add('/MD');
      case OS.android:
        systemLibraries.addAll(['log', 'z', 'dl', 'c++_static', 'c++abi']);
      case OS.iOS || OS.macOS:
        systemLibraries.addAll(['z', 'pthread', 'dl', 'c++']);
        linkFlags.addAll([
          '-framework',
          'Foundation',
          '-framework',
          'SystemConfiguration',
        ]);
      case OS.linux:
        systemLibraries.addAll(['z', 'pthread', 'dl', 'stdc++']);
      default:
        throw UnsupportedError('Unsupported targetOS: $targetOS');
    }

    final sources = input.assets.code.map((a) => a.file!.toFilePath()).toList();

    final linker = CLinker.library(
      name: 'mars',
      assetName: 'mars_bindings_generated.dart',
      libraries: [...opensslLibs, ...systemLibraries],
      libraryDirectories: [opensslLibDir],
      flags: linkFlags,
    );

    await linker.run(
      input: input,
      output: output,
      sources: sources,
      linkModePreference: LinkModePreference.dynamic,
      logger: logger,
    );
  });
}

/// Resolve OpenSSL library directory from the vendored layout.
///
/// For iOS, the target SDK (device vs simulator) selects between the arm64
/// device slice and the Apple Silicon simulator slice.
String? _opensslLibDir(
  String marsRoot,
  OS os,
  Architecture arch, {
  IOSSdk? iosSdk,
}) {
  final base = '$marsRoot/openssl/openssl_lib_${osToDir(os)}';
  return switch ((os, arch)) {
    (OS.android, Architecture.arm) => '$base/armeabi-v7a',
    (OS.android, Architecture.arm64) => '$base/arm64-v8a',
    (OS.android, Architecture.ia32) => '$base/x86',
    (OS.android, Architecture.x64) => '$base/x86_64',
    // iOS: arm64 serves both device and Apple Silicon simulator, but with
    // different OpenSSL slices; x64 is the Intel simulator slice.
    (OS.iOS, Architecture.arm64) => iosSdk == IOSSdk.iPhoneSimulator
        ? '$base/simulator_arm64'
        : '$base/arm64',
    (OS.iOS, Architecture.x64) => '$base/x64',
    (OS.macOS, Architecture.arm64) => '$base/arm64',
    (OS.macOS, Architecture.x64) => '$base/x64',
    (OS.linux, Architecture.arm) => '$base/arm32',
    (OS.linux, Architecture.arm64) => '$base/arm64',
    (OS.linux, Architecture.ia32) => '$base/x86',
    (OS.linux, Architecture.x64) => '$base/x64',
    (OS.windows, Architecture.arm64) => '$base/arm64',
    (OS.windows, Architecture.x64) => '$base/x64',
    (OS.windows, Architecture.ia32) => '$base/x86',
    _ => null,
  };
}

String osToDir(OS os) => switch (os) {
  OS.android => 'android',
  OS.iOS => 'ios',
  OS.macOS => 'macos',
  OS.linux => 'linux',
  OS.windows => 'windows',
  _ => throw UnsupportedError('Unsupported OS: $os'),
};
