import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

import 'util.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    final targetSdk = targetOS == .iOS ? input.config.code.iOS.targetSdk : null;

    final forcedIncludes = targetOS == .windows
        ? <String>['src/mars/comm/projdef.h']
        : <String>[];

    final flags = targetOS == .windows
        ? <String>[
            // Match upstream mars Windows builds (CMake/VS default) and the
            // ConanCenter openssl/3.5.9 prebuilt libs (compiler.runtime=dynamic):
            // both use the /MD runtime, so mars must not force /MT. The 10/26
            // successful Windows build compiled all modules with /MD.
            '/MP', '/MD',
            // Upstream warning suppressions.
            '/wd4003', '/wd4819', '/wd4996', '/wd4244', '/wd4101',
            '/wd4200', '/wd4800', '/wd4005', '/wd4334',
            // CMake's default MSVC C++ flags (Modules/Platform/Windows-MSVC.cmake:
            // _FLAGS_CXX = "${_GR} /EHsc", plus /W3 in the platform flags and
            // /D_WINDOWS in the platform defines). native_toolchain_c invokes
            // cl.exe directly and does NOT inherit CMake defaults, so /GR (RTTI),
            // /EHsc (C++ exceptions) and /W3 must be spelled out here; without
            // /EHsc every translation unit using try/catch emits warning C4530
            // ("C++ exception handler used, but unwind semantics are not enabled").
            '/W3', '/GR', '/EHsc',
            // Required on MSVC 19.5x+ for xlogger TSF preprocessor macros.
            '/Zc:preprocessor',
            // Mars gates C++14-only code behind __cplusplus > 201103L.
            '/Zc:__cplusplus',
          ]
        : <String>[];

    final tencentParts = [
      CBuilder.library(
        name: 'stn',
        assetName: 'stn.g.dart',
        sources: [
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
        ],
        includes: [
          'src/mars/stn/',
          'src/mars/stn/src/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('stn', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'sdt',
        assetName: 'sdt.g.dart',
        sources: [
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
        ],
        includes: [
          'src/mars/sdt/',
          'src/mars/sdt/src/',
          'src/',
          'src/mars/',
          'src/mars/boot/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('sdt', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'app',
        assetName: 'app.g.dart',
        sources: [
          'src/mars/app/app_logic.cc',
          'src/mars/app/app_manager.cc',
          'src/mars/app/src/traffic_statistics.cc',
        ],
        includes: [
          'src/mars/app/',
          'src/mars/app/src/',
          'src/',
          'src/mars/',
          'src/mars/boot/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('app', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'baseevent',
        assetName: 'baseevent.g.dart',
        sources: [
          'src/mars/baseevent/src/active_logic.cc',
          'src/mars/baseevent/src/baseprj.cc',
          'src/mars/baseevent/src/baseprjevent.cc',
        ],
        includes: [
          'src/mars/baseevent/',
          'src/mars/baseevent/src/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('baseevent', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'xlog',
        assetName: 'xlog.g.dart',
        sources: [
          // appender_unittest.cc is a test and is excluded.
          'src/mars/xlog/src/appender.cc',
          'src/mars/xlog/src/formater.cc',
          'src/mars/xlog/src/log_base_buffer.cc',
          'src/mars/xlog/src/log_zlib_buffer.cc',
          'src/mars/xlog/src/log_zstd_buffer.cc',
          'src/mars/xlog/src/xlogger_interface.cc',
          'src/mars/xlog/crypt/log_crypt.cc',
          'src/mars/xlog/crypt/micro-ecc-master/uECC.c',
          if (targetOS == .iOS || targetOS == .macOS)
            'src/mars/xlog/objc/objc_console.mm',
        ],
        includes: [
          'src/mars/xlog/',
          'src/mars/xlog/src/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/comm/xlogger/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/',
            'src/mars/comm/windows/zlib/',
          ],
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('xlog', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'boot',
        assetName: 'boot.g.dart',
        sources: [
          // boot/src does not exist upstream; boot root only has context.cc.
          'src/mars/boot/context.cc',
        ],
        includes: [
          'src/mars/boot/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('boot', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'comm',
        assetName: 'comm.g.dart',
        sources: [
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
          if (targetOS != .windows) ...[
            // Removed by upstream on Windows only (COMM_REMOVE_FILES).
            'src/mars/comm/network/local_routetable.cc',
            'src/mars/comm/socket/getsocktcpinfo.cc',
            // Shared unix socket sources (socketbreaker_unittest.cc is a test).
            'src/mars/comm/unix/socket/socketbreaker.cc',
            'src/mars/comm/unix/socket/socketpoll.cc',
            'src/mars/comm/unix/socket/socketselect.cc',
          ],
          if (targetOS == .android) ...[
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
          if (targetOS == .iOS || targetOS == .macOS) ...[
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
          if (targetOS == .windows) ...[
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
          if (targetOS == .linux) ...[
            'src/mars/comm/unix/platform_comm.cc',
            'src/mars/comm/unix/xlogger_threadinfo.cc',
          ],
        ],
        includes: [
          'src/mars/comm/',
          'src/mars/comm/alarm/',
          'src/mars/comm/assert/',
          'src/mars/comm/corepattern/',
          'src/mars/comm/crypt/',
          'src/mars/comm/debugger/',
          'src/mars/comm/dns/',
          'src/mars/comm/messagequeue/',
          'src/mars/comm/network/',
          'src/mars/comm/socket/',
          'src/mars/comm/thread/',
          'src/mars/comm/xlogger/',
          'src/mars/comm/owl/',
          'src/',
          'src/mars/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/',
            'src/mars/comm/windows/SocketSelect/',
            'src/mars/comm/windows/thread/',
            'src/mars/comm/windows/win32/',
            'src/mars/comm/windows/zlib/',
          ],
        ],
        forcedIncludes: forcedIncludes,
        flags: flags,
        defines: _getDefines('comm', targetOS, targetArchitecture),
      ),
      CBuilder.library(
        name: 'boost',
        assetName: 'boost.g.dart',
        sources: [
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
          if (targetOS == .windows) ...[
            'src/mars/boost/libs/thread/src/win32/thread.cpp',
            'src/mars/boost/libs/thread/src/win32/tss_dll.cpp',
            'src/mars/boost/libs/thread/src/win32/tss_pe.cpp',
          ],
          if (targetOS != .windows) ...[
            'src/mars/boost/libs/thread/src/pthread/once.cpp',
            'src/mars/boost/libs/thread/src/pthread/once_atomic.cpp',
            'src/mars/boost/libs/thread/src/tss_null.cpp',
          ],
          if (targetOS == .android) ...[
            'src/mars/boost/libs/coroutine/src/exceptions.cpp',
            'src/mars/boost/libs/coroutine/src/detail/coroutine_context.cpp',
            'src/mars/boost/libs/coroutine/src/posix/stack_traits.cpp',
            'src/mars/boost/libs/context/src/execution_context.cpp',
            'src/mars/boost/libs/context/src/posix/stack_traits.cpp',
          ],
          if (targetOS == .android) ..._getBoostAsmSources(targetArchitecture),
        ],
        includes: [
          'src/mars/',
          'src/mars/boost/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        flags: targetOS == .windows
            ? const [
                '/MP',
                '/MD',
                '/w',
                '/W3',
                '/GR',
                '/EHsc',
                '/Zc:preprocessor',
                '/Zc:__cplusplus',
              ]
            : const ['-w'],
        defines: {
          ..._getDefines('boost', targetOS, targetArchitecture),
          'BOOST_NO_EXCEPTIONS': null,
        },
      ),
      CBuilder.library(
        name: 'zstd',
        assetName: 'zstd.g.dart',
        sources: [
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
          // lib/legacy
          'src/mars/zstd/lib/legacy/zstd_v01.c',
          'src/mars/zstd/lib/legacy/zstd_v02.c',
          'src/mars/zstd/lib/legacy/zstd_v03.c',
          'src/mars/zstd/lib/legacy/zstd_v04.c',
          'src/mars/zstd/lib/legacy/zstd_v05.c',
          'src/mars/zstd/lib/legacy/zstd_v06.c',
          'src/mars/zstd/lib/legacy/zstd_v07.c',
        ],
        includes: [
          'src/mars/zstd/lib/',
          'src/mars/zstd/lib/common/',
          'src/mars/zstd/lib/compress/',
          'src/mars/zstd/lib/decompress/',
          'src/mars/zstd/lib/deprecated/',
          'src/mars/zstd/lib/dictBuilder/',
          'src/mars/zstd/lib/legacy/',
        ],
      ),
    ];
    for (final tencentPart in tencentParts) {
      await tencentPart.run(
        input: input,
        output: output,
        routing: input.config.linkingEnabled
            ? [ToLinkHook(input.packageName)]
            : [],
        linkModePreference: .static,
      );
    }

    final builder = CBuilder.library(
      name: 'mars',
      assetName: 'src/mars.g.dart',
      sources: ['src/mars.cpp'],
      includes: ['src/', if (targetOS == .windows) 'src/mars/comm/windows/'],
      forcedIncludes: forcedIncludes,
      flags: flags,
      defines: _getDefines('mars', targetOS, targetArchitecture),
      frameworks: frameworks,
      libraries: [
        ...tencentParts.map((tencentPart) => tencentPart.name),
        ...getSystemLibraries(targetOS),
        ...getOpensslLibraries(targetOS),
      ],
      libraryDirectories: [
        '.',
        getOpensslLibraryDirectory(
          input.packageRoot,
          targetOS,
          targetArchitecture,
          targetSdk,
        ),
      ],
    );
    await builder.run(
      input: input,
      output: output,
      routing: input.config.linkingEnabled
          ? [ToLinkHook(input.packageName)]
          : [ToAppBundle()],
      linkModePreference: input.config.linkingEnabled ? .static : .dynamic,
    );
  });
}

List<String> _getBoostAsmSources(Architecture targetArchitecture) {
  final architectureName = switch (targetArchitecture) {
    .arm => 'arm_aapcs',
    .arm64 => 'arm64_aapcs',
    .ia32 => 'i386_sysv',
    .x64 => 'x86_64_sysv',
    _ => throw UnsupportedError('No boost context asm for $targetArchitecture'),
  };
  return [
    'src/mars/boost/libs/context/src/asm/jump_${architectureName}_elf_gas.S',
    'src/mars/boost/libs/context/src/asm/make_${architectureName}_elf_gas.S',
  ];
}

Map<String, String?> _getDefines(
  String projectName,
  OS targetOS,
  Architecture targetArchitecture,
) => {
  'XLOGGER_TAG': '"mars::$projectName"',
  if (targetOS == .android) 'ANDROID': null,
  if (targetOS == .windows) ...{
    '_WIN32': null,
    'WIN32': null,
    // /D_WINDOWS is part of CMake's default MSVC platform defines
    // (Windows-MSVC.cmake); not inherited when cl.exe is invoked directly.
    '_WINDOWS': null,
    'UNICODE': null,
    '_UNICODE': null,
    'NOMINMAX': null,
    '_LIB': null,
    '__WIN32__': null,
    if (targetArchitecture == Architecture.x64 ||
        targetArchitecture == Architecture.arm64) ...{
      '_WIN64': null,
      'WIN64': null,
    },
  },
};
