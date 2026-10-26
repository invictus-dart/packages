// Build hook: compiles the vendored Tencent/Mars SDK with native_toolchain_c
// for every target in the platform matrix (Android, iOS, macOS, Linux, Windows).
// Each Mars module is compiled into its own static library; the link hook
// produces the final dynamic library.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final packageRoot = input.packageRoot.toFilePath();
    final marsRoot = '$packageRoot/src/mars';
    final codeConfig = input.config.code;
    final targetOS = codeConfig.targetOS;
    final targetArch = codeConfig.targetArchitecture;
    // iOS SDK (iPhoneOS device vs iPhoneSimulator) determines which vendored
    // OpenSSL slice to use: device arm64 vs simulator arm64.
    final iosSdk = targetOS == OS.iOS ? codeConfig.iOS.targetSdk : null;
    final isWindows = targetOS == OS.windows;
    final isAndroid = targetOS == OS.android;
    final isApple = targetOS == OS.iOS || targetOS == OS.macOS;
    final isLinux = targetOS == OS.linux;

    // --- Compiler configuration -------------------------------------------
    final baseIncludes = <String>[
      '$packageRoot/src',
      marsRoot,
      // Module include dirs.
      ...[
        'comm',
        'comm/alarm',
        'comm/assert',
        'comm/corepattern',
        'comm/crypt',
        'comm/debugger',
        'comm/dns',
        'comm/messagequeue',
        'comm/network',
        'comm/socket',
        'comm/thread',
        'comm/xlogger',
        'comm/owl',
        'boot',
        'boot/src',
        'boost',
        'app',
        'app/src',
        'baseevent/src',
        'xlog',
        'xlog/src',
        'xlog/crypt',
        'xlog/crypt/micro-ecc-master',
        'sdt',
        'sdt/src',
        'sdt/src/activecheck',
        'sdt/src/checkimpl',
        'sdt/src/tools',
        'stn',
        'stn/src',
      ].map((d) => '$marsRoot/$d'),
      '$marsRoot/rapidjson',
      '$marsRoot/zstd/lib',
      // zstd C sources use bare includes resolved from sibling dirs.
      ...[
        'common',
        'compress',
        'decompress',
        'dictBuilder',
        'legacy',
        'deprecated',
      ].map((d) => '$marsRoot/zstd/lib/$d'),
    ];

    final platformIncludes = <String>[
      if (isWindows) ...[
        '$marsRoot/comm/windows',
        '$marsRoot/comm/windows/SocketSelect',
        '$marsRoot/comm/windows/thread',
        '$marsRoot/comm/windows/win32',
        '$marsRoot/comm/windows/zlib',
      ],
      if (isApple) ...['$marsRoot/comm/objc', '$marsRoot/xlog/objc'],
      if (isAndroid || isLinux) ...[
        '$marsRoot/comm/unix',
        '$marsRoot/comm/unix/socket',
        if (isAndroid) '$marsRoot/comm/android',
      ],
    ];

    final windowsDefines = <String, String?>{
      '_WIN32': null,
      'WIN32': null,
      'UNICODE': null,
      '_UNICODE': null,
      'NOMINMAX': null,
      '_LIB': null,
      '__WIN32__': null,
      if (targetArch == Architecture.x64 || targetArch == Architecture.arm64)
        '_WIN64': null,
      'WIN64': null,
    };

    final windowsFlags = <String>[
      '/MP', '/MD',
      // Upstream warning suppressions.
      '/wd4003', '/wd4819', '/wd4996', '/wd4244', '/wd4101',
      '/wd4200', '/wd4800', '/wd4005', '/wd4334',
      // Required on MSVC 19.5x+ for xlogger TSF preprocessor macros.
      '/Zc:preprocessor',
      // Mars gates C++14-only code behind __cplusplus > 201103L.
      '/Zc:__cplusplus',
    ];

    // OpenSSL headers and libraries from vendored layout.
    final opensslIncludeDir = '$marsRoot/openssl/include';
    final opensslLibDir = _opensslLibDir(
      marsRoot,
      targetOS,
      targetArch,
      iosSdk: iosSdk,
    );
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

    final includes = <String>[
      ...baseIncludes,
      ...platformIncludes,
      opensslIncludeDir,
    ].where((dir) => Directory(dir).existsSync()).toList();

    final defines = <String, String?>{
      'XLOGGER_TAG': '"mars::mars"',
      if (isWindows) ...windowsDefines,
      if (isAndroid) 'ANDROID': null,
    };
    final flags = isWindows ? <String>[...windowsFlags] : <String>[];

    final projdef = '$marsRoot/comm/projdef.h';

    // --- Source collection ------------------------------------------------
    List<String> collect(
      String module,
      List<String> dirs, {
      List<String> excludeFilePatterns = const [],
    }) {
      final files = <String>[];
      for (final dir in dirs) {
        final fullDir = '$marsRoot/$module${dir.isEmpty ? '' : '/$dir'}';
        final directory = Directory(fullDir);
        if (!directory.existsSync()) continue;
        for (final entity in directory.listSync(recursive: false)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          if (!(name.endsWith('.c') ||
              name.endsWith('.cc') ||
              name.endsWith('.cpp') ||
              name.endsWith('.mm')))
            continue;
          if (excludeFilePatterns.any(name.contains)) continue;
          files.add(entity.path);
        }
      }
      return files;
    }

    final commSources = collect(
      'comm',
      [
        '',
        'alarm',
        'assert',
        'crypt',
        'network',
        'socket',
        'xlogger',
        'corepattern',
        'dns',
        'messagequeue',
        'owl/mpl',
        if (isWindows) ...[
          'windows',
          'windows/zlib',
          'windows/win32',
          'windows/sys',
          'windows/SocketSelect',
        ],
        if (!isWindows) 'unix/socket',
        if (isAndroid) ...['android', 'unix'],
        if (isApple) 'objc',
        if (isLinux) 'unix',
      ],
      excludeFilePatterns: [
        '_unittest.cc',
        '_mock.cc',
        if (isWindows) ...['local_routetable', 'getsocktcpinfo'],
      ],
    );
    if (isApple) commSources.add('$marsRoot/comm/debugger/debugger_utils.c');

    final bootSources = collect(
      'boot',
      ['', 'src'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );
    final appSources = collect(
      'app',
      ['', 'src'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );
    final baseeventSources = collect(
      'baseevent',
      ['src'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );
    final xlogSources = collect(
      'xlog',
      ['src', 'crypt', 'crypt/micro-ecc-master', if (isApple) 'objc'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );
    final sdtSources = collect(
      'sdt',
      ['', 'src', 'src/activecheck', 'src/checkimpl', 'src/tools'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );
    final stnSources = collect(
      'stn',
      ['', 'src'],
      excludeFilePatterns: const ['_unittest.cc', '_mock.cc'],
    );

    final zstdSources = <String>[
      for (final entity in Directory(
        '$marsRoot/zstd/lib',
      ).listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.c')) entity.path,
    ];

    final boostList = <String>[
      'libs/atomic/src/lockpool.cpp',
      'libs/date_time/src/gregorian/date_generators.cpp',
      'libs/date_time/src/gregorian/gregorian_types.cpp',
      'libs/date_time/src/gregorian/greg_month.cpp',
      'libs/date_time/src/gregorian/greg_weekday.cpp',
      'libs/date_time/src/posix_time/posix_time_types.cpp',
      'libs/exception/src/clone_current_exception_non_intrusive.cpp',
      'libs/filesystem/src/codecvt_error_category.cpp',
      'libs/filesystem/src/operations.cpp',
      'libs/filesystem/src/path.cpp',
      'libs/filesystem/src/path_traits.cpp',
      'libs/filesystem/src/portability.cpp',
      'libs/filesystem/src/unique_path.cpp',
      'libs/filesystem/src/utf8_codecvt_facet.cpp',
      'libs/filesystem/src/windows_file_codecvt.cpp',
      'libs/iostreams/src/file_descriptor.cpp',
      'libs/iostreams/src/mapped_file.cpp',
      'libs/smart_ptr/src/sp_collector.cpp',
      'libs/smart_ptr/src/sp_debug_hooks.cpp',
      'libs/system/src/error_code.cpp',
      'libs/thread/src/future.cpp',
      if (isWindows) ...[
        'libs/thread/src/win32/thread.cpp',
        'libs/thread/src/win32/tss_dll.cpp',
        'libs/thread/src/win32/tss_pe.cpp',
      ],
      if (!isWindows) ...[
        'libs/thread/src/pthread/once.cpp',
        'libs/thread/src/pthread/once_atomic.cpp',
        'libs/thread/src/tss_null.cpp',
      ],
    ].map((p) => '$marsRoot/boost/$p').toList();
    if (isAndroid) boostList.addAll(_androidBoostSources(marsRoot, targetArch));

    final bridgeSources = ['$packageRoot/src/mars.cpp'];

    // --- Build each module as a static library ----------------------------
    final modules = <String, _Module>{
      'comm': _Module(commSources, forceProjdef: true),
      'boot': _Module(bootSources, forceProjdef: true),
      'app': _Module(appSources, forceProjdef: true),
      'baseevent': _Module(baseeventSources, forceProjdef: true),
      'xlog': _Module(xlogSources, forceProjdef: true),
      'sdt': _Module(sdtSources, forceProjdef: true),
      'stn': _Module(stnSources, forceProjdef: true),
      'zstd': _Module(zstdSources, forceProjdef: false),
      'boost': _Module(
        boostList,
        forceProjdef: false,
        flags: isWindows ? const ['/MP', '/MD', '/w'] : const ['-w'],
      ),
      'mars_bridge': _Module(bridgeSources, forceProjdef: true),
    };

    final linkingEnabled = input.config.linkingEnabled;
    final buildDir = input.outputDirectory.toFilePath();

    for (final entry in modules.entries) {
      if (!linkingEnabled && entry.key == 'mars_bridge') continue;
      final module = entry.value;
      final builder = CBuilder.library(
        name: entry.key,
        assetName: linkingEnabled ? entry.key : null,
        language: Language.c,
        sources: module.sources,
        includes: includes,
        forcedIncludes: module.forceProjdef && isWindows ? [projdef] : const [],
        defines: defines,
        flags: [...flags, ...module.flags],
      );
      await builder.run(
        input: input,
        output: output,
        routing: linkingEnabled ? [ToLinkHook(input.packageName)] : const [],
        linkModePreference: LinkModePreference.static,
      );
    }

    if (!linkingEnabled) {
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

      final opensslLibs = isWindows
          ? const ['libcrypto', 'libssl']
          : const ['crypto', 'ssl'];
      final finalBuilder = CBuilder.library(
        name: 'mars',
        assetName: 'src/mars.g.dart',
        language: Language.c,
        sources: bridgeSources,
        includes: includes,
        forcedIncludes: isWindows ? [projdef] : const [],
        defines: defines,
        flags: [...flags, ...linkFlags],
        libraries: [
          ...modules.keys.where((name) => name != 'mars_bridge'),
          ...opensslLibs,
          ...systemLibraries,
        ],
        libraryDirectories: [buildDir, opensslLibDir],
      );
      await finalBuilder.run(
        input: input,
        output: output,
        routing: const [ToAppBundle()],
        linkModePreference: LinkModePreference.dynamic,
      );
    }
  });
}

/// Boost coroutine + context sources required only by Android.
List<String> _androidBoostSources(String marsRoot, Architecture arch) {
  final sources = <String>[];
  for (final dir in [
    'libs/coroutine/src',
    'libs/coroutine/src/detail',
    'libs/coroutine/src/posix',
    'libs/context/src',
    'libs/context/src/posix',
  ]) {
    final directory = Directory('$marsRoot/boost/$dir');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: false)) {
      if (entity is File &&
          (entity.path.endsWith('.cpp') || entity.path.endsWith('.c'))) {
        sources.add(entity.path);
      }
    }
  }
  final asmFiles = switch (arch) {
    Architecture.arm => const [
      'jump_arm_aapcs_elf_gas.S',
      'make_arm_aapcs_elf_gas.S',
    ],
    Architecture.arm64 => const [
      'jump_arm64_aapcs_elf_gas.S',
      'make_arm64_aapcs_elf_gas.S',
    ],
    Architecture.ia32 => const [
      'jump_i386_sysv_elf_gas.S',
      'make_i386_sysv_elf_gas.S',
    ],
    Architecture.x64 => const [
      'jump_x86_64_sysv_elf_gas.S',
      'make_x86_64_sysv_elf_gas.S',
    ],
    _ => throw UnsupportedError(
      'No boost context asm for Android ${arch.name}; supported: '
      'arm (armeabi-v7a), arm64 (arm64-v8a), ia32 (x86), x64 (x86_64)',
    ),
  };
  for (final asm in asmFiles) {
    final path = '$marsRoot/boost/libs/context/src/asm/$asm';
    if (File(path).existsSync()) sources.add(path);
  }
  return sources;
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
    (OS.iOS, Architecture.arm64) =>
      iosSdk == IOSSdk.iPhoneSimulator
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

class _Module {
  final List<String> sources;
  final bool forceProjdef;
  final List<String> flags;

  const _Module(
    this.sources, {
    required this.forceProjdef,
    this.flags = const [],
  });
}
