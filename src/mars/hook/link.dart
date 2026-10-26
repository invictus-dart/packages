// Link hook: links the static libraries produced by hook/build.dart together
// with the OpenSSL prebuilt static libs and Windows system libraries into a
// single dynamic library (`mars.dll` on Windows).
//
// This replaces the upstream `merge_win_static_libs` + final link step.

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
    final isWindows = codeConfig.targetOS == OS.windows;

    // OpenSSL prebuilt static libs ship per architecture (x86 / x64).
    String? opensslLibDir;
    final systemLibraries = <String>[];
    if (isWindows) {
      switch (codeConfig.targetArchitecture) {
        case Architecture.arm64:
          opensslLibDir = '$marsRoot/openssl/openssl_lib_windows/arm64';
        case Architecture.x64:
          opensslLibDir = '$marsRoot/openssl/openssl_lib_windows/x64';
        default:
          throw UnsupportedError(
            'No prebuilt OpenSSL for Windows '
            '${codeConfig.targetArchitecture.name}; '
            'available: arm64, x64 (OpenSSL 3.5.9); '
            'x86 requires building OpenSSL 3.5.9 from source',
          );
      }
      systemLibraries.addAll([
        // OpenSSL static libs (prebuilt).
        'libcrypto',
        'libssl',
        // Windows system libraries referenced by the Mars sources.
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
    }

    // All code assets produced by the build hook are the per-module static
    // libraries; link them into the final dynamic library.
    final sources = input.assets.code.map((a) => a.file!.toFilePath()).toList();

    final linker = CLinker.library(
      name: 'mars',
      assetName: 'mars_bindings_generated.dart',
      libraries: systemLibraries,
      libraryDirectories: [?opensslLibDir],
      flags: isWindows ? const ['/MD'] : const [],
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
