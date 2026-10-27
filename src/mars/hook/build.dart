// Build hook: compiles the vendored Tencent/Mars SDK with native_toolchain_c
// for every target in the platform matrix (Android, iOS, macOS, Linux, Windows).
// Each Mars module is compiled into its own static library, then all static
// libraries are linked together with OpenSSL and platform system libraries into
// a single dynamic library. When linkingEnabled is true, the dylib is routed to
// the link hook (link.dart) which applies treeshake; otherwise it goes directly
// into the app bundle.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final packageRoot = input.packageRoot;
    final codeConfig = input.config.code;
    final targetOS = codeConfig.targetOS;
    final targetArch = codeConfig.targetArchitecture;
    // iOS SDK (iPhoneOS device vs iPhoneSimulator) determines which vendored
    // OpenSSL slice to use: device arm64 vs simulator arm64.
    final iosSdk = targetOS == OS.iOS ? codeConfig.iOS.targetSdk : null;
    final isWindows = targetOS == OS.windows;
    final isAndroid = targetOS == OS.android;
    final isDarwin = targetOS == OS.iOS || targetOS == OS.macOS;
    final isLinux = targetOS == OS.linux;

    final includes = <String>[
      'src',
      'src/mars',
      // Module include dirs.
      'src/mars/comm',
      'src/mars/comm/alarm',
      'src/mars/comm/assert',
      'src/mars/comm/corepattern',
      'src/mars/comm/crypt',
      'src/mars/comm/debugger',
      'src/mars/comm/dns',
      'src/mars/comm/messagequeue',
      'src/mars/comm/network',
      'src/mars/comm/socket',
      'src/mars/comm/thread',
      'src/mars/comm/xlogger',
      'src/mars/comm/owl',
      'src/mars/boot',
      'src/mars/boost',
      'src/mars/app',
      'src/mars/app/src',
      'src/mars/baseevent/src',
      'src/mars/xlog',
      'src/mars/xlog/src',
      'src/mars/xlog/crypt',
      'src/mars/xlog/crypt/micro-ecc-master',
      'src/mars/sdt',
      'src/mars/sdt/src',
      'src/mars/sdt/src/activecheck',
      'src/mars/sdt/src/checkimpl',
      'src/mars/sdt/src/tools',
      'src/mars/stn',
      'src/mars/stn/src',
      'src/mars/rapidjson',
      // zstd C sources use bare includes resolved from sibling dirs.
      'src/mars/zstd/lib',
      'src/mars/zstd/lib/common',
      'src/mars/zstd/lib/compress',
      'src/mars/zstd/lib/decompress',
      'src/mars/zstd/lib/deprecated',
      'src/mars/zstd/lib/dictBuilder',
      'src/mars/zstd/lib/legacy',
      // openssl
      'src/mars/openssl/include',
      if (isAndroid || isLinux) ...[
        'src/mars/comm/unix',
        'src/mars/comm/unix/socket',
        if (isAndroid) 'src/mars/comm/android',
      ],
      if (isDarwin) ...['src/mars/comm/objc', 'src/mars/xlog/objc'],
      if (isWindows) ...[
        'src/mars/comm/windows',
        'src/mars/comm/windows/SocketSelect',
        'src/mars/comm/windows/thread',
        'src/mars/comm/windows/win32',
        'src/mars/comm/windows/zlib',
      ],
    ];
    final forceIncudes = isWindows
        ? <String>['src/mars/comm/projdef.h']
        : const <String>[];
    final flags = isWindows
        ? <String>[
            // Match upstream mars Windows builds (CMake/VS default) and the
            // ConanCenter openssl/3.5.9 prebuilt libs (compiler.runtime=dynamic):
            // both use the /MD runtime, so mars must not force /MT. The 10/26
            // successful Windows build compiled all modules with /MD.
            '/MP', '/MD',
            // Upstream warning suppressions.
            '/wd4003', '/wd4819', '/wd4996', '/wd4244', '/wd4101',
            '/wd4200', '/wd4800', '/wd4005', '/wd4334',
            // Required on MSVC 19.5x+ for xlogger TSF preprocessor macros.
            '/Zc:preprocessor',
            // Mars gates C++14-only code behind __cplusplus > 201103L.
            '/Zc:__cplusplus',
          ]
        : <String>[];
    final defines = <String, String?>{
      'XLOGGER_TAG': '"mars::mars"',
      if (isAndroid) 'ANDROID': null,
      if (isWindows) ...{
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
      },
    };

    // --- Source collection ------------------------------------------------
    // All module sources are listed as flat, explicit file paths (no
    // directory enumeration / GLOB). The lists mirror what upstream
    // mars/*/CMakeLists.txt file(GLOB ...) resolves per platform, with tests
    // (unittest/mock/testspy) and jni bridge files stripped.

    final appSources = <String>[
      'src/mars/app/app_logic.cc',
      'src/mars/app/app_manager.cc',
      'src/mars/app/src/traffic_statistics.cc',
    ];
    final baseeventSources = <String>[
      'src/mars/baseevent/src/active_logic.cc',
      'src/mars/baseevent/src/baseprj.cc',
      'src/mars/baseevent/src/baseprjevent.cc',
    ];
    final bootSources = <String>[
      // boot/src does not exist upstream; boot root only has context.cc.
      'src/mars/boot/context.cc',
    ];
    final commSources = <String>[
      // comm root; channel_unittest.cc is a test and is excluded.
      'src/mars/comm/adler32.c',
      'src/mars/comm/alarm.cc',
      'src/mars/comm/anr.cc',
      'src/mars/comm/autobuffer.cc',
      'src/mars/comm/basepacker.cc',
      'src/mars/comm/boost_exception.cc',
      'src/mars/comm/comm_frequency_limit.cc',
      'src/mars/comm/fd_info.cc',
      'src/mars/comm/http.cc',
      'src/mars/comm/memdbg.cc',
      'src/mars/comm/mmap_util.cc',
      'src/mars/comm/platform_comm_base.cc',
      'src/mars/comm/ptrbuffer.cc',
      'src/mars/comm/singleton.cc',
      'src/mars/comm/strutil.cc',
      'src/mars/comm/tickcount.cc',
      'src/mars/comm/time_utils.c',
      'src/mars/comm/tinyxml2.cc',
      'src/mars/comm/unique_resource_factory.cc',
      // comm submodules.
      'src/mars/comm/alarm/alarm_manager.cc',
      'src/mars/comm/assert/__assert.c',
      'src/mars/comm/crypt/ibase64.cc',
      'src/mars/comm/crypt/pkcs7_padding.c',
      'src/mars/comm/network/getaddrinfo_with_timeout.cc',
      'src/mars/comm/network/getdnssvraddrs.cc',
      'src/mars/comm/network/getgateway.c',
      'src/mars/comm/network/getifaddrs.cc',
      'src/mars/comm/network/netinfo_util.cc',
      'src/mars/comm/socket/block_socket.cc',
      'src/mars/comm/socket/complexconnect.cc',
      'src/mars/comm/socket/local_ipstack.cc',
      'src/mars/comm/socket/nat64_prefix_util.cc',
      'src/mars/comm/socket/socket_address.cc',
      'src/mars/comm/socket/tcpclient.cc',
      'src/mars/comm/socket/tcpclient_fsm.cc',
      'src/mars/comm/socket/tcpserver.cc',
      'src/mars/comm/socket/tcpserver_fsm.cc',
      'src/mars/comm/socket/udpclient.cc',
      'src/mars/comm/socket/udpserver.cc',
      'src/mars/comm/socket/unix_socket.cc',
      'src/mars/comm/xlogger/loginfo_extract.c',
      'src/mars/comm/xlogger/xlogger.cc',
      'src/mars/comm/xlogger/xlogger_category.cc',
      'src/mars/comm/xlogger/xloggerbase.c',
      'src/mars/comm/corepattern/coreservice_base.cc',
      'src/mars/comm/dns/dns.cc',
      'src/mars/comm/messagequeue/message_queue.cc',
      // Removed by upstream on Windows only (COMM_REMOVE_FILES).
      if (!isWindows) ...[
        'src/mars/comm/network/local_routetable.cc',
        'src/mars/comm/socket/getsocktcpinfo.cc',
      ],
      // Shared unix socket sources (socketbreaker_unittest.cc is a test).
      if (!isWindows) ...[
        'src/mars/comm/unix/socket/socketbreaker.cc',
        'src/mars/comm/unix/socket/socketpoll.cc',
        'src/mars/comm/unix/socket/socketselect.cc',
      ],
      if (isAndroid) ...[
        'src/mars/comm/android/dumpcrash_stack.cc',
        'src/mars/comm/android/getprocessname.c',
        'src/mars/comm/android/wakeuplock.cc',
        // Official Android branch compiles only unix/xlogger_threadinfo.cc
        // from the unix dir; the real platform_comm lives in jni/ upstream,
        // which is stripped for FFI. unix/platform_comm.cc (stub impl) is the
        // functional replacement so platform_comm symbols stay defined.
        'src/mars/comm/unix/xlogger_threadinfo.cc',
        'src/mars/comm/unix/platform_comm.cc',
      ],
      if (isDarwin) ...[
        'src/mars/comm/objc/Reachability.mm',
        'src/mars/comm/objc/ThreadOperationQueue.mm',
        'src/mars/comm/objc/data_protect_attr.mm',
        'src/mars/comm/objc/objc_timer.mm',
        'src/mars/comm/objc/platform_comm.mm',
        'src/mars/comm/objc/scope_autoreleasepool.mm',
        'src/mars/comm/objc/xlogger_threadinfo.mm',
        // Only debugger_utils.c is built upstream; testspy files excluded.
        'src/mars/comm/debugger/debugger_utils.c',
      ],
      if (isWindows) ...[
        'src/mars/comm/windows/TssGC.cpp',
        'src/mars/comm/windows/projdef.cc',
        'src/mars/comm/windows/unistd.cpp',
        'src/mars/comm/windows/uwp_compatible.cpp',
        'src/mars/comm/windows/xlogger_threadinfo.cpp',
        'src/mars/comm/windows/win32/NetUtil.cpp',
        'src/mars/comm/windows/win32/platform_comm.cpp',
        'src/mars/comm/windows/sys/time.c',
        'src/mars/comm/windows/SocketSelect/socketbreaker.cc',
        'src/mars/comm/windows/SocketSelect/socketselect2.cc',
        // Upstream comm Windows branch additionally compiles the bundled zlib.
        'src/mars/comm/windows/zlib/compress.c',
        'src/mars/comm/windows/zlib/crc32.c',
        'src/mars/comm/windows/zlib/deflate.c',
        'src/mars/comm/windows/zlib/gzclose.c',
        'src/mars/comm/windows/zlib/gzlib.c',
        'src/mars/comm/windows/zlib/gzread.c',
        'src/mars/comm/windows/zlib/gzwrite.c',
        'src/mars/comm/windows/zlib/infback.c',
        'src/mars/comm/windows/zlib/inffast.c',
        'src/mars/comm/windows/zlib/inflate.c',
        'src/mars/comm/windows/zlib/inftrees.c',
        'src/mars/comm/windows/zlib/trees.c',
        'src/mars/comm/windows/zlib/uncompr.c',
        'src/mars/comm/windows/zlib/zutil.c',
      ],
      if (isLinux) ...[
        'src/mars/comm/unix/platform_comm.cc',
        'src/mars/comm/unix/xlogger_threadinfo.cc',
      ],
    ];
    final sdtSources = <String>[
      'src/mars/sdt/sdt_logic.cc',
      'src/mars/sdt/sdt_manager.cc',
      'src/mars/sdt/src/sdt_core.cc',
      'src/mars/sdt/src/activecheck/basechecker.cc',
      'src/mars/sdt/src/activecheck/dnschecker.cc',
      'src/mars/sdt/src/activecheck/httpchecker.cc',
      'src/mars/sdt/src/activecheck/pingchecker.cc',
      'src/mars/sdt/src/activecheck/tcpchecker.cc',
      'src/mars/sdt/src/checkimpl/base_netinfo_query.cc',
      'src/mars/sdt/src/checkimpl/dnsquery.cc',
      'src/mars/sdt/src/checkimpl/http_detector.cc',
      'src/mars/sdt/src/checkimpl/httpquery.cc',
      'src/mars/sdt/src/checkimpl/pingquery.cc',
      'src/mars/sdt/src/checkimpl/tcpquery.cc',
      'src/mars/sdt/src/tools/netchecker_trafficmonitor.cc',
    ];
    final stnSources = <String>[
      'src/mars/stn/stn.cc',
      'src/mars/stn/stn_callback_bridge.cc',
      'src/mars/stn/stn_logic.cc',
      'src/mars/stn/stn_manager.cc',
      'src/mars/stn/src/anti_avalanche.cc',
      'src/mars/stn/src/dynamic_timeout.cc',
      'src/mars/stn/src/flow_limit.cc',
      'src/mars/stn/src/frequency_limit.cc',
      'src/mars/stn/src/longlink.cc',
      'src/mars/stn/src/longlink_connect_monitor.cc',
      'src/mars/stn/src/longlink_identify_checker.cc',
      'src/mars/stn/src/longlink_metadata.cc',
      'src/mars/stn/src/longlink_speed_test.cc',
      'src/mars/stn/src/longlink_task_manager.cc',
      'src/mars/stn/src/net_channel_factory.cc',
      'src/mars/stn/src/net_check_logic.cc',
      'src/mars/stn/src/net_core.cc',
      'src/mars/stn/src/net_source.cc',
      'src/mars/stn/src/netsource_timercheck.cc',
      'src/mars/stn/src/proxy_test.cc',
      'src/mars/stn/src/shortlink.cc',
      'src/mars/stn/src/shortlink_task_manager.cc',
      'src/mars/stn/src/signalling_keeper.cc',
      'src/mars/stn/src/simple_ipport_sort.cc',
      'src/mars/stn/src/smart_heartbeat.cc',
      'src/mars/stn/src/task_intercept.cc',
      'src/mars/stn/src/task_profile.cc',
      'src/mars/stn/src/tcp_socket_operator.cc',
      'src/mars/stn/src/timing_sync.cc',
      'src/mars/stn/src/weak_network_logic.cc',
      'src/mars/stn/src/zombie_task_manager.cc',
    ];
    final xlogSources = <String>[
      // appender_unittest.cc is a test and is excluded.
      'src/mars/xlog/src/appender.cc',
      'src/mars/xlog/src/formater.cc',
      'src/mars/xlog/src/log_base_buffer.cc',
      'src/mars/xlog/src/log_zlib_buffer.cc',
      'src/mars/xlog/src/log_zstd_buffer.cc',
      'src/mars/xlog/src/xlogger_interface.cc',
      'src/mars/xlog/crypt/log_crypt.cc',
      'src/mars/xlog/crypt/micro-ecc-master/uECC.c',
      if (isDarwin) 'src/mars/xlog/objc/objc_console.mm',
    ];

    final boostSources = <String>[
      'src/mars/boost/libs/atomic/src/lockpool.cpp',
      'src/mars/boost/libs/date_time/src/gregorian/date_generators.cpp',
      'src/mars/boost/libs/date_time/src/gregorian/gregorian_types.cpp',
      'src/mars/boost/libs/date_time/src/gregorian/greg_month.cpp',
      'src/mars/boost/libs/date_time/src/gregorian/greg_weekday.cpp',
      'src/mars/boost/libs/date_time/src/posix_time/posix_time_types.cpp',
      'src/mars/boost/libs/exception/src/clone_current_exception_non_intrusive.cpp',
      'src/mars/boost/libs/filesystem/src/codecvt_error_category.cpp',
      'src/mars/boost/libs/filesystem/src/operations.cpp',
      'src/mars/boost/libs/filesystem/src/path.cpp',
      'src/mars/boost/libs/filesystem/src/path_traits.cpp',
      'src/mars/boost/libs/filesystem/src/portability.cpp',
      'src/mars/boost/libs/filesystem/src/unique_path.cpp',
      'src/mars/boost/libs/filesystem/src/utf8_codecvt_facet.cpp',
      'src/mars/boost/libs/filesystem/src/windows_file_codecvt.cpp',
      'src/mars/boost/libs/iostreams/src/file_descriptor.cpp',
      'src/mars/boost/libs/iostreams/src/mapped_file.cpp',
      'src/mars/boost/libs/smart_ptr/src/sp_collector.cpp',
      'src/mars/boost/libs/smart_ptr/src/sp_debug_hooks.cpp',
      'src/mars/boost/libs/system/src/error_code.cpp',
      'src/mars/boost/libs/thread/src/future.cpp',
      if (isWindows) ...[
        'src/mars/boost/libs/thread/src/win32/thread.cpp',
        'src/mars/boost/libs/thread/src/win32/tss_dll.cpp',
        'src/mars/boost/libs/thread/src/win32/tss_pe.cpp',
      ],
      if (!isWindows) ...[
        'src/mars/boost/libs/thread/src/pthread/once.cpp',
        'src/mars/boost/libs/thread/src/pthread/once_atomic.cpp',
        'src/mars/boost/libs/thread/src/tss_null.cpp',
      ],
      if (isAndroid) ...[
        'src/mars/boost/libs/coroutine/src/exceptions.cpp',
        'src/mars/boost/libs/coroutine/src/detail/coroutine_context.cpp',
        'src/mars/boost/libs/coroutine/src/posix/stack_traits.cpp',
        'src/mars/boost/libs/context/src/execution_context.cpp',
        'src/mars/boost/libs/context/src/posix/stack_traits.cpp',
      ],
      if (isAndroid) ..._getAndroidBoostAsmSources(targetArch),
    ];
    // Official zstd build (zstd/build/cmake/lib/CMakeLists.txt) compiles only
    // common/compress/decompress/dictBuilder/deprecated; the legacy dir is
    // gated behind ZSTD_LEGACY_SUPPORT which Mars' root CMakeLists does not
    // enable, so legacy/zstd_v0*.c must not be collected.
    final zstdSources = <String>[
      // lib/common.
      'src/mars/zstd/lib/common/debug.c',
      'src/mars/zstd/lib/common/entropy_common.c',
      'src/mars/zstd/lib/common/error_private.c',
      'src/mars/zstd/lib/common/fse_decompress.c',
      'src/mars/zstd/lib/common/pool.c',
      'src/mars/zstd/lib/common/threading.c',
      'src/mars/zstd/lib/common/xxhash.c',
      'src/mars/zstd/lib/common/zstd_common.c',
      // lib/compress.
      'src/mars/zstd/lib/compress/fse_compress.c',
      'src/mars/zstd/lib/compress/hist.c',
      'src/mars/zstd/lib/compress/huf_compress.c',
      'src/mars/zstd/lib/compress/zstd_compress.c',
      'src/mars/zstd/lib/compress/zstd_compress_literals.c',
      'src/mars/zstd/lib/compress/zstd_compress_sequences.c',
      'src/mars/zstd/lib/compress/zstd_double_fast.c',
      'src/mars/zstd/lib/compress/zstd_fast.c',
      'src/mars/zstd/lib/compress/zstd_lazy.c',
      'src/mars/zstd/lib/compress/zstd_ldm.c',
      'src/mars/zstd/lib/compress/zstd_opt.c',
      'src/mars/zstd/lib/compress/zstdmt_compress.c',
      // lib/decompress.
      'src/mars/zstd/lib/decompress/huf_decompress.c',
      'src/mars/zstd/lib/decompress/zstd_ddict.c',
      'src/mars/zstd/lib/decompress/zstd_decompress.c',
      'src/mars/zstd/lib/decompress/zstd_decompress_block.c',
      // lib/deprecated.
      'src/mars/zstd/lib/deprecated/zbuff_common.c',
      'src/mars/zstd/lib/deprecated/zbuff_compress.c',
      'src/mars/zstd/lib/deprecated/zbuff_decompress.c',
      // lib/dictBuilder.
      'src/mars/zstd/lib/dictBuilder/cover.c',
      'src/mars/zstd/lib/dictBuilder/divsufsort.c',
      'src/mars/zstd/lib/dictBuilder/fastcover.c',
      'src/mars/zstd/lib/dictBuilder/zdict.c',
    ];

    // --- Build each module as a static library ----------------------------
    // All Mars SDK modules compiled as static libraries with assetName set so
    // they can be consumed by the final linking step below. The bridge code
    // (mars.cpp) is not compiled as a separate static library — it's included
    // directly in the final dynamic library since it only contains FFI bindings.
    // First-party Mars modules share the global defines/flags and get the
    // projdef.h forced include (equivalent to the official /FI on Windows).
    final marsParts = <_MarsPart>[
      _MarsPart(
        name: 'app',
        sources: appSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'baseevent',
        sources: baseeventSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'boot',
        sources: bootSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'comm',
        sources: commSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'sdt',
        sources: sdtSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'stn',
        sources: stnSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
      _MarsPart(
        name: 'xlog',
        sources: xlogSources,
        includes: includes,
        forceIncludes: forceIncudes,
        flags: flags,
        defines: defines,
      ),
    ];
    // Third-party modules keep their own defines/flags only and must NOT
    // inherit global flags (e.g. /wd* on Windows) or the projdef include.
    // boost: -DBOOST_NO_EXCEPTIONS + -w (official CMake), zstd: no extras.
    final thirdPartyParts = <_MarsPart>[
      _MarsPart(
        name: 'boost',
        sources: boostSources,
        includes: includes,
        defines: {'BOOST_NO_EXCEPTIONS': null},
        // boost's mpl/preprocessor recursion needs the conformant preprocessor
        // on MSVC 19.5x+ (same reason the global flags carry /Zc:preprocessor).
        // Verified: the 10/26 successful build compiled boost with the global
        // flags including /Zc:preprocessor and /Zc:__cplusplus.
        flags: isWindows
            ? const ['/MP', '/MD', '/w', '/Zc:preprocessor', '/Zc:__cplusplus']
            : const ['-w'],
      ),
      _MarsPart(name: 'zstd', sources: zstdSources, includes: includes),
    ];

    for (final marsPart in marsParts) {
      await _buildMarsPart(marsPart, input: input, output: output);
    }
    for (final thirdPartyPart in thirdPartyParts) {
      await _buildMarsPart(thirdPartyPart, input: input, output: output);
    }

    // --- Final dynamic library --------------------------------------------
    // Always produce the final dynamic library by linking all static modules
    // together with OpenSSL and platform system libraries. Routing depends on
    // linkingEnabled:
    //   - false → ToAppBundle (directly into the app bundle)
    //   - true  → ToLinkHook (pass through link hook for treeshake)
    final systemLibs = switch (targetOS) {
      .android => ['log', 'z'],
      .iOS || .macOS => ['z', 'pthread', 'dl'],
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
      .linux => ['z', 'pthread', 'dl'],
      _ => [],
    };

    final opensslLibDir = _getOpensslLibsDir(
      packageRoot,
      targetOS,
      targetArch,
      iosSdk: iosSdk,
    );
    final opensslLibs = isWindows
        ? const ['libcrypto', 'libssl']
        : const ['crypto', 'ssl'];

    final builder = CBuilder.library(
      name: 'mars',
      assetName: 'src/mars.g.dart',
      sources: ['src/mars.cpp'],
      includes: includes,
      forcedIncludes: forceIncudes,
      frameworks: ['Foundation', 'SystemConfiguration'],
      libraries: [
        ...marsParts.map((m) => m.name),
        ...thirdPartyParts.map((m) => m.name),
        ...systemLibs,
        ...opensslLibs,
      ],
      libraryDirectories: ['.', opensslLibDir],
      flags: flags,
      defines: defines,
      language: .cpp,
    );
    await builder.run(
      input: input,
      output: output,
      routing: input.config.linkingEnabled
          ? [ToLinkHook(input.packageName)]
          : const [ToAppBundle()],
      linkModePreference: LinkModePreference.dynamic,
    );
  });
}

// --- Source collection ------------------------------------------------
// Sources are declared as flat explicit paths (see the source lists above);
// there is intentionally no directory-enumeration helper left in this file.

/// Boost context asm files required only by Android, selected per ABI.
List<String> _getAndroidBoostAsmSources(Architecture architecture) {
  final architectureName = switch (architecture) {
    .arm => 'arm_aapcs',
    .arm64 => 'arm64_aapcs',
    .ia32 => 'i386_sysv',
    .x64 => 'x86_64_sysv',
    _ => throw UnsupportedError('No boost context asm for $architecture'),
  };
  return [
    'src/mars/boost/libs/context/src/asm/jump_${architectureName}_elf_gas.S',
    'src/mars/boost/libs/context/src/asm/make_${architectureName}_elf_gas.S',
  ];
}

/// Resolve OpenSSL library directory from the vendored layout.
///
/// For iOS, the target SDK (device vs simulator) selects between the arm64
/// device slice and the Apple Silicon simulator slice.
String _getOpensslLibsDir(
  Uri packageRoot,
  OS os,
  Architecture architecture, {
  IOSSdk? iosSdk,
}) {
  final architectureName = switch (os) {
    .android => switch (architecture) {
      .arm => 'armeabi-v7a',
      .arm64 => 'arm64-v8a',
      .ia32 => 'x86',
      .x64 => 'x86_64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $os, $architecture',
      ),
    },
    .iOS => switch (architecture) {
      .arm64 => switch (iosSdk) {
        .iPhoneOS => 'arm64',
        .iPhoneSimulator => 'simulator_arm64',
        _ => throw UnsupportedError(
          'Unsupported iOS SDK: $os, $architecture, $iosSdk',
        ),
      },
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $os, $architecture',
      ),
    },
    .macOS => switch (architecture) {
      .arm64 => 'arm64',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $os, $architecture',
      ),
    },
    .windows => switch (architecture) {
      .arm64 => 'arm64',
      .ia32 => 'x86',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $os, $architecture',
      ),
    },
    .linux => switch (architecture) {
      .arm => 'arm32',
      .arm64 => 'arm64',
      .ia32 => 'x86',
      .x64 => 'x64',
      _ => throw UnsupportedError(
        'Unsupported architecture: $os, $architecture',
      ),
    },
    _ => throw UnsupportedError('Unsupported os: $os'),
  };
  return packageRoot
      .resolve('src/mars/openssl/openssl_lib_${os.name}/$architectureName/')
      .toFilePath();
}

Future<void> _buildMarsPart(
  _MarsPart marsPart, {
  required BuildInput input,
  required BuildOutputBuilder output,
  Logger? logger,
}) async {
  final builder = CBuilder.library(
    name: marsPart.name,
    sources: marsPart.sources,
    includes: marsPart.includes,
    forcedIncludes: marsPart.forceIncludes,
    flags: marsPart.flags,
    defines: marsPart.defines,
  );
  await builder.run(
    input: input,
    output: output,
    logger: logger,
    linkModePreference: .static,
  );
}

class _MarsPart {
  final String name;
  final List<String> sources;
  final List<String> includes;
  final List<String> forceIncludes;
  final Map<String, String?> defines;
  final List<String> flags;

  const _MarsPart({
    required this.name,
    required this.sources,
    this.includes = const [],
    this.forceIncludes = const [],
    this.flags = const [],
    this.defines = const {},
  });
}
