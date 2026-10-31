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

    final tencentParts = [
      CBuilder.library(
        name: 'zstd',
        assetName: 'zstd_bindings_generated.dart',
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
          // Upstream builds zstd via zstd/build/cmake/lib/CMakeLists.txt with
          // ZSTD_LEGACY_SUPPORT off (default): lib/legacy is neither compiled
          // nor added to the include path.
        ],
        includes: [
          'src/mars/zstd/lib/',
          'src/mars/zstd/lib/common/',
          'src/mars/zstd/lib/compress/',
          'src/mars/zstd/lib/decompress/',
          'src/mars/zstd/lib/deprecated/',
          'src/mars/zstd/lib/dictBuilder/',
        ],
        // 上游 lib/CMakeLists.txt L108-114（MSVC 分支）：ZSTD_BUILD_STATIC
        // （根 CMakeLists.txt L18 设 ON）→ ZSTD_HEAPMODE=0;_CRT_SECURE_NO_WARNINGS。
        // ZSTD_DLL_EXPORT=1 仅 shared 库，本地只编静态库，不加。
        defines: {
          if (targetOS == .windows) ...{
            'ZSTD_HEAPMODE': '0',
            '_CRT_SECURE_NO_WARNINGS': null,
          },
        },
      ),
      CBuilder.library(
        name: 'boost',
        assetName: 'boost_bindings_generated.dart',
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
          if (targetOS == .android) ...[
            'src/mars/boost/libs/coroutine/src/exceptions.cpp',
            'src/mars/boost/libs/coroutine/src/detail/coroutine_context.cpp',
            'src/mars/boost/libs/coroutine/src/posix/stack_traits.cpp',
            'src/mars/boost/libs/context/src/execution_context.cpp',
            'src/mars/boost/libs/context/src/posix/stack_traits.cpp',
            ..._getBoostAsmSources(targetArchitecture),
          ],
        ],
        includes: [
          'src/mars/',
          'src/mars/boost/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        // boost 上游只 include utils.cmake、不 include CMakeExtraFlags.txt
        // (boost/CMakeLists.txt L9)，故 includeExtraFlags: false（无 /wd 集）。
        // 模块单独声明：-w (boost/CMakeLists.txt L5 add_compile_options(-w))。
        flags: targetOS == .windows
            ? [
                '/w',
                ..._getUtilsCxxFlags(targetOS),
                ..._getPatchFlags(targetOS, targetArchitecture),
              ]
            : const ['-w'],
        // 模块单独声明：-DBOOST_NO_EXCEPTIONS (boost/CMakeLists.txt L14)。
        // 注意：XLOGGER_TAG 沿用本地现状 "mars::boost"；上游 project 名为
        // mars-boost，对应 "mars::mars-boost"（已知差异，见对比文档）。
        defines: {
          ..._getUtilsDefines('boost', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
          'BOOST_NO_EXCEPTIONS': null,
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'comm1',
        assetName: 'comm1_bindings_generated.dart',
        sources: [
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
          'src/mars/comm/tinyxml2.cc',
          'src/mars/comm/unique_resource_factory.cc',
          'src/mars/comm/alarm/alarm_manager.cc',
          'src/mars/comm/crypt/ibase64.cc',
          'src/mars/comm/network/getaddrinfo_with_timeout.cc',
          'src/mars/comm/network/getdnssvraddrs.cc',
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
          'src/mars/comm/xlogger/xlogger.cc',
          'src/mars/comm/xlogger/xlogger_category.cc',
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
            'src/mars/comm/android/wakeuplock.cc',
            'src/mars/comm/unix/xlogger_threadinfo.cc',
            'src/mars/comm/jni/ifaddrs.cc',
            'src/mars/comm/jni/platform_comm.cc',
            'src/mars/comm/jni/jnicat/jnicat_core.cpp',
            'src/mars/comm/jni/util/comm_function.cc',
            'src/mars/comm/jni/util/scope_jenv.cc',
            'src/mars/comm/jni/util/scoped_jstring.cc',
            'src/mars/comm/jni/util/var_cache.cc',
          ],
          if (targetOS == .iOS || targetOS == .macOS) ...[
            'src/mars/comm/objc/Reachability.mm',
            'src/mars/comm/objc/ThreadOperationQueue.mm',
            'src/mars/comm/objc/data_protect_attr.mm',
            'src/mars/comm/objc/objc_timer.mm',
            'src/mars/comm/objc/platform_comm.mm',
            'src/mars/comm/objc/scope_autoreleasepool.mm',
            'src/mars/comm/objc/xlogger_threadinfo.mm',
          ],
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/TssGC.cpp',
            'src/mars/comm/windows/projdef.cc',
            'src/mars/comm/windows/unistd.cpp',
            'src/mars/comm/windows/uwp_compatible.cpp',
            'src/mars/comm/windows/xlogger_threadinfo.cpp',
            'src/mars/comm/windows/win32/NetUtil.cpp',
            'src/mars/comm/windows/win32/platform_comm.cpp',
            'src/mars/comm/windows/SocketSelect/socketbreaker.cc',
            'src/mars/comm/windows/SocketSelect/socketselect2.cc',
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        // 模块单独声明：Android 下 -DUSING_XLOG_WEAK_FUNC (comm/CMakeLists.txt
        // L117)，使编入 comm 的 xlogger.cc 为弱符号，避免与 xlog 强符号重复。
        defines: {
          ..._getUtilsDefines('comm', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
          if (targetOS == .android) 'USING_XLOG_WEAK_FUNC': null,
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'comm2',
        assetName: 'comm2_bindings_generated.dart',
        sources: [
          'src/mars/comm/adler32.c',
          'src/mars/comm/time_utils.c',
          'src/mars/comm/assert/__assert.c',
          'src/mars/comm/crypt/pkcs7_padding.c',
          'src/mars/comm/network/getgateway.c',
          'src/mars/comm/xlogger/loginfo_extract.c',
          'src/mars/comm/xlogger/xloggerbase.c',
          if (targetOS == .android) ...[
            'src/mars/comm/android/getprocessname.c',
          ],
          if (targetOS == .iOS || targetOS == .macOS) ...[
            // Only debugger_utils.c is built upstream; testspy files excluded.
            'src/mars/comm/debugger/debugger_utils.c',
          ],
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/sys/time.c',
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('comm', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
          if (targetOS == .android) 'USING_XLOG_WEAK_FUNC': null,
        },
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'boot',
        assetName: 'boot_bindings_generated.dart',
        sources: [
          // boot/src does not exist upstream; boot root only has context.cc.
          'src/mars/boot/context.cc',
          if (targetOS == .android) 'src/mars/boot/jni/context_wrapper.cc',
        ],
        includes: [
          'src/mars/boot/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/openssl/include/',
          if (targetOS == .windows) 'src/mars/comm/windows/',
        ],
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('boot', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'xlog1',
        assetName: 'xlog1_bindings_generated.dart',
        sources: [
          // appender_unittest.cc is a test and is excluded.
          'src/mars/xlog/src/appender.cc',
          'src/mars/xlog/src/formater.cc',
          'src/mars/xlog/src/log_base_buffer.cc',
          'src/mars/xlog/src/log_zlib_buffer.cc',
          'src/mars/xlog/src/log_zstd_buffer.cc',
          'src/mars/xlog/src/xlogger_interface.cc',
          'src/mars/xlog/crypt/log_crypt.cc',
          if (targetOS == .iOS || targetOS == .macOS)
            'src/mars/xlog/objc/objc_console.mm',
          if (targetOS == .android) ...[
            'src/mars/xlog/jni/ConsoleLog.cc',
            'src/mars/xlog/jni/Java2C_Xlog.cc',
          ],
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('xlog', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'xlog2',
        assetName: 'xlog2_bindings_generated.dart',
        sources: [
          'src/mars/xlog/crypt/micro-ecc-master/uECC.c',
          // 本地 xlog 日志解码器（vendored 树外的库化改编，源上游
          // xlog/crypt/decode_log_file_c_impl/decode_log_file.c），由
          // mars_xlog_decode FFI 桥接调用；依赖 micro-ecc/zstd/zlib 头。
          'src/xlog/decode.c',
        ],
        includes: [
          'src/mars/xlog/',
          'src/mars/xlog/src/',
          // decode.c: "micro-ecc-master/uECC.h"。
          'src/mars/xlog/crypt/',
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('xlog', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'baseevent',
        assetName: 'baseevent_bindings_generated.dart',
        sources: [
          'src/mars/baseevent/src/active_logic.cc',
          'src/mars/baseevent/src/baseprj.cc',
          'src/mars/baseevent/src/baseprjevent.cc',
          if (targetOS == .android)
            'src/mars/baseevent/jni/com_tencent_mars_BaseEvent.cc',
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('baseevent', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'app',
        assetName: 'app_bindings_generated.dart',
        sources: [
          'src/mars/app/app_logic.cc',
          'src/mars/app/app_manager.cc',
          'src/mars/app/src/traffic_statistics.cc',
          if (targetOS == .android) ...[
            'src/mars/app/jni/app_manager_callback_wrapper.cc',
            'src/mars/app/jni/app_manager_wrapper.cc',
            'src/mars/app/jni/com_tencent_mars_app_AppLogic_C2Java.cc',
          ],
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('app', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'sdt',
        assetName: 'sdt_bindings_generated.dart',
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
          if (targetOS == .android) ...[
            'src/mars/sdt/jni/com_tencent_mars_sdt_SdtLogic_C2Java.cc',
            'src/mars/sdt/jni/com_tencent_mars_sdt_SdtLogic_Java2C.cc',
            'src/mars/sdt/jni/sdt_manager_callback_wrapper.cc',
            'src/mars/sdt/jni/sdt_manager_wrapper.cc',
          ],
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('sdt', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'stn',
        assetName: 'stn_bindings_generated.dart',
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
          if (targetOS == .android) ...[
            'src/mars/stn/jni/com_tencent_mars_stn_StnLogic_C2Java.cc',
            'src/mars/stn/jni/com_tencent_mars_stn_StnLogic_Java2C.cc',
            'src/mars/stn/jni/stn_manager_callback_wrapper.cc',
            'src/mars/stn/jni/stn_manager_wrapper.cc',
          ],
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
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getPatchFlags(targetOS, targetArchitecture),
        ],
        defines: {
          ..._getUtilsDefines('stn', targetOS, targetArchitecture),
          ..._getPatchDefines(targetOS),
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
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
      assetName: 'src/mars_bindings_generated.dart',
      sources: [
        'src/mars.cpp',
        if (targetOS == .android) ...[
          'src/jni/import.cc',
          'src/mars/libraries/mars_android_sdk/jni/JNI_OnLoad.cc',
          'src/mars/libraries/mars_android_sdk/jni/longlink_packer.cc',
          'src/mars/libraries/mars_android_sdk/jni/shortlink_packer.cc',
        ],
      ],
      includes: [
        'src/',
        'src/mars/',
        if (targetOS == .windows) 'src/mars/comm/windows/',
      ],
      // 主模块对应上游"根 mars"目标（marsxlog / marsstn，仅 Android）：
      // 根 CMakeLists.txt L27 include(comm/utils.cmake)、不 include
      // CMakeExtraFlags.txt、无 MSVC /FI projdef.h。因此：
      // - flags 只用 utils 层 + 本地补丁（不吃 extraFlags 的 /wd 集 / Android 警告集）；
      // - 不用 forcedIncludes（上游根无 /FI；src/mars.cpp 不依赖 projdef.h）；
      // - defines 为 utils 层（XLOGGER_TAG=mars::mars）+ 本地补丁；std 为 gnu++14。
      flags: [
        ..._getUtilsCxxFlags(targetOS),
        ..._getPatchFlags(targetOS, targetArchitecture),
      ],
      defines: {
        ..._getUtilsDefines('mars', targetOS, targetArchitecture),
        ..._getPatchDefines(targetOS),
      },
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
      std: _getStd(targetOS),
      optimizationLevel: _getOptimizationLevel(targetOS),
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
    _ => throw UnsupportedError(
      'Unsupported architecture: $targetArchitecture',
    ),
  };
  return [
    'src/mars/boost/libs/context/src/asm/jump_${architectureName}_elf_gas.S',
    'src/mars/boost/libs/context/src/asm/make_${architectureName}_elf_gas.S',
  ];
}

/// 上游模块在 MSVC 分支强制包含的头（/FI projdef.h）
///
/// comm/CMakeLists.txt L72 (`/FI"../projdef.h"`)，boot/app/baseevent/sdt/stn/
/// xlog 均为 `/FI"../../comm/projdef.h"`。
List<String> _getForcedIncludes(OS targetOS) => [
  if (targetOS == .windows) 'src/mars/comm/projdef.h',
];

/// 上游来源：comm/utils.cmake
///
/// - MSVC 侧 `/MP`（L34）与 `/MD→/MT` 全局替换后的 `/MT`（L41-51）
/// - 非 MSVC 平台另有 -fno-exceptions / -fpic / -fPIC / -ffunction-sections
/// / -fdata-sections / -Os 等 flags，以及 Android 的 -Werror 警告集
/// （CMakeExtraFlags.txt L3-12）
List<String> _getUtilsCxxFlags(
  OS targetOS, {
  BuildMode buildMode = .release,
}) => switch (targetOS) {
  .android => [
    // L55（非 MSVC 通用）：-fno-exceptions。
    '-fno-exceptions',
    // L69：CXX -std=gnu++14 由 _getStd 承担不重复；-fpic 由 pic:true 覆盖。
    // -Wno-deprecated-register
    '-Wno-deprecated-register',
  ],
  .iOS || .macOS => [
    // L55（非 MSVC 通用）：-fno-exceptions。
    '-fno-exceptions',
    // L82：CXX -std=gnu++14 -stdlib=libc++（-std 由 _getStd 承担；libc++ 为 Apple 默认）。
    '-stdlib=libc++',
    // L83-86 配置层：release = -g -gline-tables-only -Os；debug = -g -O0
    // （debug 另含 L54 的 -O0，去重；-DDEBUG 由 buildModeDefine 自动）。
    // -Os/-O0 在 optimizationLevel（默认 .o3/-O3）之后，last-wins 生效。
    if (buildMode == .debug) '-g',
    if (buildMode == .release) ...['-g', '-gline-tables-only'],
  ],
  .windows => [
    '/MP',
    '/MT',
    // L26 debug /DDEBUG 由 buildModeDefine 自动；L37 release /Zi。
    if (buildMode == .release) '/Zi',
  ],
  .linux => [
    // L55（非 MSVC 通用）：-fno-exceptions。
    '-fno-exceptions',
    // L111-112：-std=gnu++14 由 _getStd 承担；-fPIC 由 pic:true 覆盖。
    // -Os 在普通层（所有构建模式生效）：release 时生效；debug 时由末尾
    // 的 -O0 覆盖（与上游 CMake 中普通 flags 在前、config flags 在后的
    // last-wins 语义一致）。
    '-ffunction-sections',
    '-fdata-sections',
  ],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// 上游 utils.cmake 中仅作用于 C（CMAKE_C_FLAGS）的 flags。
///
/// 说明：
/// - Android L70：`-fdata-sections`（C-only）。
/// - Linux L112：`-fPIC`（由 pic:true 覆盖）`-ffunction-sections -fdata-sections
///   -Os`（-Os 属优化层，由 optimizationLevel 控制）→ 补 sections 两项。
/// - Apple：C 侧无普通（非 config）flags；L83-86 的 release/debug 追加项
///   （-g -gline-tables-only -Os / -g -O0）属构建配置层，不在此补全。
/// - Windows：MSVC 分支 /MP 是 CXX-only（L34）；/MD→/MT 替换（L49-51）
///   作用于 C_FLAGS 系列 → C 侧保留 /MT 结果。
List<String> _getUtilsCFlags(OS targetOS, {BuildMode buildMode = .release}) =>
    switch (targetOS) {
      .android => ['-fdata-sections'],
      .iOS || .macOS => [
        // L85：C_FLAGS_DEBUG = -g -O0。
        if (buildMode == .debug) '-g',
        // L83：C_FLAGS_RELEASE = -g -gline-tables-only -Os。
        if (buildMode == .release) ...['-g', '-gline-tables-only'],
      ],
      .linux => ['-ffunction-sections', '-fdata-sections'],
      .windows => ['/MT', if (buildMode == .release) '/Zi'],
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

/// 上游来源：comm/CMakeExtraFlags.txt
///
/// - MSVC 侧 `/wd4003 ... /wd4334`（L19-21）
/// - 非 MSVC 平台另有 -fno-exceptions / -fpic / -fPIC / -ffunction-sections
/// / -fdata-sections / -Os 等 flags，以及 Android 的 -Werror 警告集
/// （CMakeExtraFlags.txt L3-12），本地 hooks 当前均未启用，保持现状。
List<String> _getExtraFlags(OS targetOS) => switch (targetOS) {
  .android => [
    // comm/CMakeExtraFlags.txt L3-9（Clang 分支；NDK 编译器为 clang，
    // GCC 分支的 -Wclobbered 不适用）：
    '-Werror', '-Wall', '-Werror=sign-compare', '-Wtype-limits',
    '-Wuninitialized', '-Wempty-body',
    '-Wconsumed',
    '-Wno-error=tautological-unsigned-zero-compare',
    '-Wno-error=char-subscripts',
    '-Wno-error=gnu-designator',
    '-Wno-error=unused-variable',
    '-Wno-error=missing-braces',
    '-Wno-error=tautological-type-limit-compare',
  ],
  .iOS || .macOS => [
    // CMakeExtraFlags.txt 的 Apple 分支仅注释掉的 -Werror -Wall（不生效）
    // '-Werror', '-Wall',
  ],
  .windows => [
    '/wd4003',
    '/wd4819',
    '/wd4996',
    '/wd4244',
    '/wd4101',
    '/wd4200',
    '/wd4800',
    '/wd4005',
    '/wd4334',
  ],
  .linux => [],
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// 本地补充 flags（对齐上游 CMake 默认环境 / 工具链差异 / 本地修正）。
///
/// - `-mthumb`：arm 架构指令集（本地工具链补充）。
/// - MSVC 侧 `/W3 /GR /EHsc`：CMake 默认 MSVC C++ flags
///   （Modules/Platform/Windows-MSVC.cmake）在 native_toolchain_c 直接调用
///   cl.exe 时不会继承，需显式补上；没有 /EHsc 时 try/catch 会触发 C4530。
///
/// 注意：`/Zc:preprocessor` 与 `/Zc:__cplusplus` 不加到全局（上游无），
/// 如后续某模块编译报错（如 xlogger TSF 宏依赖 /Zc:preprocessor，
/// __cplusplus 门控的 C++14 代码依赖 /Zc:__cplusplus），再在具体模块添加。
List<String> _getPatchFlags(OS targetOS, Architecture targetArchitecture) => [
  if (targetArchitecture == .arm) '-mthumb',
  if (targetOS == .windows) ...['/W3', '/GR', '/EHsc'],
];

/// 上游来源：comm/utils.cmake。
///
/// - `XLOGGER_TAG="mars::<PROJECT_NAME>"`（L7，随模块 projectName）。
/// - MSVC 平台宏（L28-32）：`_WIN32 WIN32 UNICODE _UNICODE NOMINMAX _LIB`
///   （64 位另加 `_WIN64 WIN64`）。
///
/// 未在此补全的 utils.cmake defines 及原因：
/// - debug 宏（MSVC /DDEBUG、非 MSVC -DDEBUG）：native_toolchain_c
///   `buildModeDefine: true`（默认）已按构建模式自动定义（debug 构建定义
///   `DEBUG`）；NDEBUG 由 `ndebugDefine: true` 自动定义。
/// - 可选 defines（默认关）：UNITTEST / DISABLE_QUIC_PROTOCOL /
///   DISABLE_PCDN_PROTOCOL / CPP_CALL_BACK / NATIVE_CALLBACK / USE_CPP_CALLBACK
///   —— 本地 hooks 未启用对应选项，保持关闭。
Map<String, String?> _getUtilsDefines(
  String projectName,
  OS targetOS,
  Architecture targetArchitecture,
) => {
  'XLOGGER_TAG': '"mars::$projectName"',
  if (targetOS == .windows) ...{
    '_WIN32': null,
    'WIN32': null,
    'UNICODE': null,
    '_UNICODE': null,
    'NOMINMAX': null,
    '_LIB': null,
    if (targetArchitecture == Architecture.x64 ||
        targetArchitecture == Architecture.arm64) ...{
      '_WIN64': null,
      'WIN64': null,
    },
  },
};

/// 本地补充 defines（对齐上游 CMake 平台默认 / 本地修正）。
///
/// - `ANDROID` / `_WINDOWS`：上游 CMake 平台默认宏，本地显式补上。
/// - `__WIN32__`：本地有意补充（上游无）。
Map<String, String?> _getPatchDefines(OS targetOS) => {
  if (targetOS == .android) 'ANDROID': null,
  if (targetOS == .windows) ...{'_WINDOWS': null, '__WIN32__': null},
};

String? _getStd(OS targetOS) => switch (targetOS) {
  .android || .iOS || .macOS || .linux => 'gnu++14',
  .windows => null,
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// 优化级别：native_toolchain_c 的 `optimizationLevel`（替代 flags 中的 -O）。
///
/// 对照上游 utils.cmake（release 当前生效）。返回 `.o3` 与省略该参数等价
/// （CBuilder.library 默认值即 `.o3`，见 clibrary.dart L104）：
/// - Android：release → `.o3`（分支 L69-70 无 -O 设置 = CMake 默认 -O3）；
///   debug → `.o0`（L54）。
/// - Apple/Linux：release → `.oS`（L83-84 / L111-112）；debug → `.o0`
///   （L85-86 / L54）。
/// - Windows：恒 `.o3`（release = CMake 默认 /O2，o3 对 MSVC 自动降级为
///   /O2，见 optimization_level.dart `o3.msvcFlag()`；debug 同样 /O2——
///   与上游 debug 默认 /Od 的差异当前不处理，仅 Release 构建）。
OptimizationLevel _getOptimizationLevel(
  OS targetOS, {
  BuildMode buildMode = .release,
}) => switch (targetOS) {
  .android || .windows => switch (buildMode) {
    .debug => .o0,
    .release => .o3,
    _ => throw UnsupportedError('Unsupported build mode: $buildMode'),
  },
  .iOS || .macOS || .linux => switch (buildMode) {
    .debug => .o0,
    .release => .oS,
    _ => throw UnsupportedError('Unsupported build mode: $buildMode'),
  },
  _ => throw UnimplementedError('Unsupported os: $targetOS'),
};
