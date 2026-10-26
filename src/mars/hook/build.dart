// Build hook: compiles the vendored Tencent/Mars SDK with native_toolchain_c
// (replacing the upstream build_windows.py / CMake scripts).
//
// Strategy (mirrors the official MSVC build):
//   * Each Mars module is compiled into its own static library (the upstream
//     CMake produces per-module static libs: comm, boot, boost, app,
//     baseevent, xlog, sdt, stn, zstd).
//   * `language: Language.c` is used on purpose: on MSVC this avoids the
//     `/TP` flag, so cl.exe compiles `.c` files as C and `.cc`/`.cpp` files as
//     C++ by extension (same as the upstream CMake build).
//   * `comm/projdef.h` is force-included (`/FI`) into every Mars translation
//     unit, exactly like the upstream `/FI"../../comm/projdef.h"`.
//   * Static libraries are routed to the link hook, which produces the final
//     single-file dynamic library (hook/link.dart).
//
// See src/mars/SOURCE.md for the full mapping to the official build.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final logger = Logger('mars-build')
      ..level = Level.ALL
      ..onRecord.listen((record) => stdout.writeln(record.message));

    final packageRoot = input.packageRoot.toFilePath();
    final marsRoot = '$packageRoot/src/mars';
    final codeConfig = input.config.code;
    final isWindows = codeConfig.targetOS == OS.windows;

    // --- Compiler configuration (official MSVC settings) ------------------
    final baseIncludes = <String>[
      // Enable `#include "mars/comm/..."` style includes.
      '$packageRoot/src',
      // Vendor root: `#include "comm/..."`, `#include "xlog/..."`, ...
      marsRoot,
      // Module roots and official per-module include dirs.
      '$marsRoot/comm',
      '$marsRoot/comm/alarm',
      '$marsRoot/comm/assert',
      '$marsRoot/comm/corepattern',
      '$marsRoot/comm/crypt',
      '$marsRoot/comm/debugger',
      '$marsRoot/comm/dns',
      '$marsRoot/comm/messagequeue',
      '$marsRoot/comm/network',
      '$marsRoot/comm/socket',
      '$marsRoot/comm/thread',
      '$marsRoot/comm/xlogger',
      '$marsRoot/comm/owl',
      '$marsRoot/boot',
      '$marsRoot/boot/src',
      '$marsRoot/boost',
      '$marsRoot/app',
      '$marsRoot/app/src',
      '$marsRoot/baseevent/src',
      '$marsRoot/xlog',
      '$marsRoot/xlog/src',
      '$marsRoot/xlog/crypt',
      '$marsRoot/xlog/crypt/micro-ecc-master',
      '$marsRoot/sdt',
      '$marsRoot/sdt/src',
      '$marsRoot/sdt/src/activecheck',
      '$marsRoot/sdt/src/checkimpl',
      '$marsRoot/sdt/src/tools',
      '$marsRoot/stn',
      '$marsRoot/stn/src',
      '$marsRoot/openssl/include',
      '$marsRoot/rapidjson',
      '$marsRoot/zstd/lib',
      // zstd C sources use bare includes (`"debug.h"`, `"bitstream.h"`, ...)
      // resolved from these sibling dirs (mirrors the zstd CMake include set).
      '$marsRoot/zstd/lib/common',
      '$marsRoot/zstd/lib/compress',
      '$marsRoot/zstd/lib/decompress',
      '$marsRoot/zstd/lib/dictBuilder',
      '$marsRoot/zstd/lib/legacy',
      '$marsRoot/zstd/lib/deprecated',
    ];

    final windowsIncludes = <String>[
      // Windows sys shims: `<sys/time.h>`, `<sys/cdefs.h>`, ...
      '$marsRoot/comm/windows',
      '$marsRoot/comm/windows/SocketSelect',
      '$marsRoot/comm/windows/thread',
      '$marsRoot/comm/windows/win32',
      '$marsRoot/comm/windows/zlib',
    ];

    final windowsDefines = <String, String?>{
      '_WIN32': null,
      'WIN32': null,
      'UNICODE': null,
      '_UNICODE': null,
      'NOMINMAX': null,
      '_LIB': null,
      if (codeConfig.targetArchitecture == Architecture.x64 ||
          codeConfig.targetArchitecture == Architecture.arm64) ...{
        '_WIN64': null,
        'WIN64': null,
      },
      // The vendored OpenSSL include dispatcher (opensslconf.h) selects the
      // Windows config via `__WIN32__` (a MinGW-ism MSVC does not predefine).
      // Without it the upstream header fails with "#error unsupported
      // platform" on every MSVC build; defining it is the documented fix.
      '__WIN32__': null,
      // Single merged XLOGGER_TAG (upstream uses "mars::<module>").
      'XLOGGER_TAG': '"mars::mars"',
    };

    final windowsFlags = <String>[
      '/MP',
      // Dynamic CRT, matching the OpenSSL 3.5.9 prebuilt static libs
      // (ConanCenter builds them with `compiler.runtime=dynamic`). A /MT
      // final DLL would leave `__imp_fgets`-style CRT imports unresolved.
      // The Dart host process itself links the dynamic CRT, so the produced
      // mars.dll has no extra runtime dependency.
      '/MD',
      // Upstream warning suppressions (comm/CMakeExtraFlags.txt).
      '/wd4003',
      '/wd4819',
      '/wd4996',
      '/wd4244',
      '/wd4101',
      '/wd4200',
      '/wd4800',
      '/wd4005',
      '/wd4334',
      // REQUIRED on modern MSVC (VS 2022 17.6+ / VS 2026): the Mars xlogger
      // TSF format-arg preprocessor machinery (PP_IF/PP_BOOL/PP_DEC/PP_SIZE
      // in comm/xlogger/preprocessor.h) only expands correctly under the
      // conformant preprocessor. The upstream Windows build (pinned to VS
      // 2019) predates this; on MSVC 19.5x the legacy preprocessor emits
      // "PP_IF_PP_BOOL_PP_DEC_PP_SIZE_" garbage. Verified against the
      // upstream CMake build, which fails identically on this toolchain.
      '/Zc:preprocessor',
      // MSVC keeps __cplusplus at 199711L by default even in C++14 mode;
      // Mars gates C++14-only code (e.g. comm/strutil.h to_string overloads)
      // behind `#if __cplusplus > 201103L`, so without this flag those
      // sections are silently compiled out and `strutil::to_string` is
      // missing from the overload set.
      '/Zc:__cplusplus',
    ];

    // native_toolchain_c's CBuilder recursively lists every include directory
    // to record output dependencies (cbuilder.dart `includeFiles`), and throws
    // if one does not exist. The vendored release tree has no `boot/src`
    // subdirectory (boot sources live in `boot/` directly), so only keep
    // include dirs that actually exist.
    final includes = <String>[
      ...baseIncludes,
      if (isWindows) ...windowsIncludes,
    ].where((dir) => Directory(dir).existsSync()).toList();
    final defines = isWindows
        ? <String, String?>{...windowsDefines}
        : <String, String?>{};
    final flags = isWindows ? <String>[...windowsFlags] : <String>[];

    // Official `/FI"../../comm/projdef.h"` (not applied to boost/zstd).
    final projdef = '$marsRoot/comm/projdef.h';

    // --- Source collection ------------------------------------------------
    //
    // Mirrors the per-module `file(GLOB ...)` lists from the upstream
    // CMakeLists.txt MSVC branch.
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
              name.endsWith('.cpp'))) {
            continue;
          }
          if (excludeFilePatterns.any(name.contains)) continue;
          files.add(entity.path);
        }
      }
      return files;
    }

    final commSources = collect(
      'comm',
      [
        '', // comm/*.cc, comm/*.c
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
        // MSVC-only source groups.
        'windows',
        'windows/zlib',
        'windows/win32',
        'windows/sys',
        'windows/SocketSelect',
      ],
      excludeFilePatterns: [
        '_unittest.cc',
        '_mock.cc',
        // Removed from the MSVC build by the upstream CMake.
        'local_routetable',
        'getsocktcpinfo',
      ],
    );

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
      ['src', 'crypt', 'crypt/micro-ecc-master'],
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

    // zstd: all .c under zstd/lib (upstream builds it via its own CMake).
    final zstdSources = <String>[
      for (final entity in Directory(
        '$marsRoot/zstd/lib',
      ).listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.c')) entity.path,
    ];

    // boost: the explicit source list from boost/CMakeLists.txt.
    final boostList = [
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
      // MSVC-only sources.
      'libs/thread/src/win32/thread.cpp',
      'libs/thread/src/win32/tss_dll.cpp',
      'libs/thread/src/win32/tss_pe.cpp',
    ].map((p) => '$marsRoot/boost/$p').toList();

    // FFI bridge (our own C++ code).
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
        flags: const ['/MP', '/MD', '/w'],
      ),
      'mars_bridge': _Module(bridgeSources, forceProjdef: true),
    };

    // When linking is enabled (e.g. `dart compile exe`, Flutter AOT builds),
    // the per-module static libraries are routed to the link hook, which
    // produces the final `mars.dll` (hook/link.dart).
    //
    // When linking is disabled (e.g. `dart test`, `dart run`), the runtime
    // loads dynamic code assets directly, so the build hook itself has to
    // produce `mars.dll`: compile the bridge against the per-module static
    // libraries (and the OpenSSL prebuilts) into a single shared library,
    // registered as the `mars_bindings_generated.dart` code asset.
    final linkingEnabled = input.config.linkingEnabled;
    final buildDir = input.outputDirectory.toFilePath();

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

    for (final entry in modules.entries) {
      // The bridge is compiled directly into the final shared library when
      // linking is disabled; skip the standalone bridge archive then.
      if (!linkingEnabled && entry.key == 'mars_bridge') continue;
      final module = entry.value;
      final builder = CBuilder.library(
        name: entry.key,
        // Registers each module's static library as a code asset routed to
        // the link hook. Without an assetName, `assets_for_linking` stays
        // empty and the link hook never produces the final DLL.
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
        logger: logger,
      );
    }

    if (!linkingEnabled && isWindows) {
      // The per-module static libraries live in the build output directory.
      final moduleLibs = <String>[];
      for (final name in modules.keys) {
        if (name == 'mars_bridge') continue;
        moduleLibs.add('$buildDir/$name.lib');
      }
      final finalBuilder = CBuilder.library(
        name: 'mars',
        assetName: 'mars_bindings_generated.dart',
        language: Language.c,
        sources: bridgeSources,
        includes: includes,
        forcedIncludes: [projdef],
        defines: defines,
        flags: flags,
        libraries: [
          ...modules.keys.where((name) => name != 'mars_bridge'),
          if (opensslLibDir != null) ...['libcrypto', 'libssl'],
          ...systemLibraries,
        ],
        libraryDirectories: [buildDir, ?opensslLibDir],
      );
      await finalBuilder.run(
        input: input,
        output: output,
        routing: const [ToAppBundle()],
        linkModePreference: LinkModePreference.dynamic,
        logger: logger,
      );
    }
  });
}

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
