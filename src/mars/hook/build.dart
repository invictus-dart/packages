import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:intl/intl.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';

import 'util.dart';
import 'openssl.dart';
import 'zstd.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;

    // MARS_BUILD_TIME / MARS_BUILD_TIMESTAMP are injected as defines so the
    // .xlog header records the actual compilation time; the vendored
    // mars/comm/verinfo.h no longer defines them (local fix, see
    // src/mars/src/README.md). The quotes are part of the value because
    // xlog/src/appender.cc concatenates the macro as a string literal.
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US');

    final opensslPart = OpensslBuilder();
    await opensslPart.run(input: input, output: output);
    final zstdPart = ZstdBuilder();
    await zstdPart.run(input: input, output: output);
    final tencentParts = [
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
        // Upstream includes utils.cmake only, not CMakeExtraFlags.txt
        // (boost/CMakeLists.txt L9) → includeExtraFlags: false (no /wd set).
        // Module-local declaration: -w (boost/CMakeLists.txt L5).
        flags: targetOS == .windows
            ? [
                '/w',
                ..._getUtilsCxxFlags(targetOS),
                ..._getCMakeFlags(targetOS, targetArchitecture),
              ]
            : const ['-w'],
        // Module-local declaration: -DBOOST_NO_EXCEPTIONS (boost/CMakeLists.txt
        // L14). Note: XLOGGER_TAG keeps the local value "mars::boost"; the
        // upstream project name is mars-boost ("mars::mars-boost") — a known,
        // documented divergence.
        defines: {
          ..._getUtilsDefines('boost', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        // Module-local declaration: Android adds -DUSING_XLOG_WEAK_FUNC
        // (comm/CMakeLists.txt L117) so xlogger.cc compiled into comm is a
        // weak symbol and does not collide with the strong one in xlog.
        defines: {
          ..._getUtilsDefines('comm', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('comm', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('boot', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          'src/mars/zstd/include/',
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/',
            'src/mars/comm/windows/zlib/',
          ],
        ],
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCxxFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('xlog', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
          // Consumed by xlog/src/appender.cc (compiled into xlog1 only):
          // written into the header of every .xlog file.
          'MARS_BUILD_TIME': '"${dateFormat.format(now)}"',
          'MARS_BUILD_TIMESTAMP': '${now.millisecondsSinceEpoch ~/ 1000}',
        },
        std: _getStd(targetOS),
        optimizationLevel: _getOptimizationLevel(targetOS),
      ),
      CBuilder.library(
        name: 'xlog2',
        assetName: 'xlog2_bindings_generated.dart',
        sources: [
          'src/mars/xlog/crypt/micro-ecc-master/uECC.c',
          // Local xlog log-file decoder (library-style adaptation of the
          // upstream xlog/crypt/decode_log_file_c_impl/decode_log_file.c,
          // outside the vendored tree). Called by the mars_xlog_decode FFI
          // bridge; depends on micro-ecc/zstd/zlib headers.
          'src/xlog/decode.c',
        ],
        includes: [
          'src/mars/xlog/',
          'src/mars/xlog/src/',
          // decode.c includes "micro-ecc-master/uECC.h".
          'src/mars/xlog/crypt/',
          'src/',
          'src/mars/',
          'src/mars/comm/',
          'src/mars/comm/xlogger/',
          'src/mars/openssl/include/',
          'src/mars/zstd/include/',
          if (targetOS == .windows) ...[
            'src/mars/comm/windows/',
            'src/mars/comm/windows/zlib/',
          ],
        ],
        forcedIncludes: _getForcedIncludes(targetOS),
        flags: [
          ..._getUtilsCFlags(targetOS),
          ..._getExtraFlags(targetOS),
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('xlog', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('baseevent', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('app', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('sdt', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
          ..._getCMakeFlags(targetOS, targetArchitecture),
          ..._getMsvcStandardPreprocessorFlags(targetOS),
        ],
        defines: {
          ..._getUtilsDefines('stn', targetOS, targetArchitecture),
          ..._getCMakeDefines(targetOS),
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
      // The main module mirrors the upstream root "mars" target (marsxlog /
      // marsstn, Android only): root CMakeLists.txt L27 includes
      // comm/utils.cmake but not CMakeExtraFlags.txt, and has no MSVC /FI
      // projdef.h. Therefore:
      // - flags use the utils set + local patches only (no extraFlags /wd or
      //   Android warning set);
      // - no forcedIncludes (upstream root has none; src/mars.cpp does not
      //   need projdef.h);
      // - defines are the utils set (XLOGGER_TAG=mars::mars) + local patches;
      //   std is gnu++14.
      flags: [
        ..._getUtilsCxxFlags(targetOS),
        ..._getCMakeFlags(targetOS, targetArchitecture),
        ..._getMsvcStandardPreprocessorFlags(targetOS),
      ],
      defines: {
        ..._getUtilsDefines('mars', targetOS, targetArchitecture),
        ..._getCMakeDefines(targetOS),
      },
      frameworks: frameworks,
      libraries: [
        ...getOpensslLibraries(targetOS),
        ...getZstdLibraries(targetOS),
        ...tencentParts.map((tencentPart) => tencentPart.name),
        ...getSystemLibraries(targetOS),
      ],
      libraryDirectories: ['.', 'openssl/out/lib', 'zstd/out/lib'],
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

/// Header force-included by upstream MSVC branches (/FI projdef.h).
///
/// comm/CMakeLists.txt L72 (`/FI"../projdef.h"`); boot/app/baseevent/sdt/stn/
/// xlog all use `/FI"../../comm/projdef.h"`.
List<String> _getForcedIncludes(OS targetOS) => [
  if (targetOS == .windows) 'src/mars/comm/projdef.h',
];

/// Upstream source: comm/utils.cmake.
///
/// - MSVC side: `/MP` (L34) and `/MT` (L41-51, after the global /MD→/MT
///   rewrite).
/// - Non-MSVC platforms additionally use -fno-exceptions / -fpic / -fPIC /
///   -ffunction-sections / -fdata-sections / -Os, plus the Android -Werror
///   warning set (CMakeExtraFlags.txt L3-12).
List<String> _getUtilsCxxFlags(OS targetOS, {BuildMode buildMode = .release}) =>
    switch (targetOS) {
      .android => [
        // L55 (non-MSVC common): -fno-exceptions.
        '-fno-exceptions',
        // L69: CXX -std=gnu++14 is handled by _getStd; -fpic by pic:true.
        // -Wno-deprecated-register
        '-Wno-deprecated-register',
      ],
      .iOS || .macOS => [
        // L55 (non-MSVC common): -fno-exceptions.
        '-fno-exceptions',
        // L82: CXX -std=gnu++14 -stdlib=libc++ (-std via _getStd; libc++ is the
        // Apple default).
        // L83-86 config layer: release = -g -gline-tables-only -Os; debug =
        // -g -O0 (debug also has L54 -O0, deduplicated; -DDEBUG comes from
        // buildModeDefine). -Os/-O0 land after optimizationLevel (default .o3),
        // last-wins.
        if (buildMode == .debug) '-g',
        if (buildMode == .release) ...['-g', '-gline-tables-only'],
      ],
      .windows => [
        '/MP',
        '/MT',
        // L26 debug /DDEBUG via buildModeDefine; L37 release /Zi.
        if (buildMode == .release) '/Zi',
      ],
      .linux => [
        // L55 (non-MSVC common): -fno-exceptions.
        '-fno-exceptions',
        // L111-112: -std=gnu++14 via _getStd; -fPIC via pic:true.
        // -Os sits in the common layer (all build modes): effective in release;
        // in debug the trailing -O0 wins (same last-wins semantics as upstream
        // CMake, where common flags precede config flags).
        '-ffunction-sections',
        '-fdata-sections',
      ],
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

/// Flags in upstream utils.cmake that apply to C only (CMAKE_C_FLAGS).
///
/// Notes:
/// - Android L70: `-fdata-sections` (C-only).
/// - Linux L112: `-fPIC` (covered by pic:true) `-ffunction-sections
///   -fdata-sections -Os` (-Os is optimization-level, handled by
///   optimizationLevel) → add the two sections flags.
/// - Apple: no common (non-config) C flags; the L83-86 release/debug
///   additions (-g -gline-tables-only -Os / -g -O0) belong to the build
///   config layer and are not duplicated here.
/// - Windows: /MP is CXX-only (L34); the /MD→/MT rewrite (L49-51) applies
///   to the C flags too → keep /MT on the C side.
List<String> _getUtilsCFlags(OS targetOS, {BuildMode buildMode = .release}) =>
    switch (targetOS) {
      .android => ['-fdata-sections'],
      .iOS || .macOS => [
        // L85: C_FLAGS_DEBUG = -g -O0.
        if (buildMode == .debug) '-g',
        // L83: C_FLAGS_RELEASE = -g -gline-tables-only -Os.
        if (buildMode == .release) ...['-g', '-gline-tables-only'],
      ],
      .linux => ['-ffunction-sections', '-fdata-sections'],
      .windows => ['/MT', if (buildMode == .release) '/Zi'],
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

/// Upstream source: comm/CMakeExtraFlags.txt.
///
/// - MSVC side: `/wd4003 ... /wd4334` (L19-21).
/// - Non-MSVC platforms additionally use -fno-exceptions / -fpic / -fPIC /
///   -ffunction-sections / -fdata-sections / -Os, plus the Android -Werror
///   warning set (CMakeExtraFlags.txt L3-12), not enabled by these hooks.
///   Kept as-is.
List<String> _getExtraFlags(OS targetOS) => switch (targetOS) {
  .android => [
    // comm/CMakeExtraFlags.txt L3-9 (Clang branch; the NDK compiler is
    // clang, the GCC-only -Wclobbered does not apply):
    '-Werror', '-Wall', '-Werror=sign-compare', '-Wtype-limits',
    '-Wuninitialized', '-Wempty-body',
    '-Wconsumed',
    '-Wno-error=tautological-unsigned-zero-compare',
    '-Wno-error=char-subscripts',
    '-Wno-error=gnu-designator',
    '-Wno-error=unused-variable',
    '-Wno-error=missing-braces',
    '-Wno-error=tautological-type-limit-compare',
    // NDK r28 clang deprecates the type-trait builtins used by the vendored
    // boost (e.g. __has_trivial_destructor -> __is_trivially_destructible),
    // and mars::comm uses std::binary_function (deprecated since C++11).
    // Keep these as warnings instead of failing the upstream -Werror gate.
    '-Wno-error=deprecated-builtins',
    '-Wno-error=deprecated-declarations',
  ],
  .iOS || .macOS => [
    // The Apple branch of CMakeExtraFlags.txt has only commented-out
    // -Werror -Wall (not effective).
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

/// Local additions (upstream CMake defaults / toolchain gaps / local fixes).
///
/// - `-mthumb`: arm instruction set (local toolchain addition).
/// - MSVC `/W3 /GR /EHsc`: the default MSVC C++ flags of CMake
///   (Modules/Platform/Windows-MSVC.cmake) are not inherited when
///   native_toolchain_c invokes cl.exe directly, so they are added
///   explicitly; without /EHsc, try/catch triggers C4530.
///
/// Note: `/Zc:preprocessor` and `/Zc:__cplusplus` are NOT global (upstream
/// has neither). Both are added per-module by
/// [_getMsvcStandardPreprocessorFlags].
List<String> _getCMakeFlags(OS targetOS, Architecture targetArchitecture) => [
  if (targetArchitecture == .arm) '-mthumb',
  if (targetOS == .windows) ...['/W3', '/GR', '/EHsc'],
];

/// Local addition: on Windows, enables the MSVC standard-conforming
/// preprocessor (`/Zc:preprocessor`) and the standard `__cplusplus` value
/// (`/Zc:__cplusplus`) for modules that use xlogger macros.
///
/// Reason 1 (`/Zc:preprocessor`): XLOGGER_ROUTER_OUTPUT in xlogger.h
/// (L414-415) relies on nested variadic macros
/// `PP_IF(PP_NUM_PARAMS(__VA_ARGS__), PP_IF(PP_DEC(...)))`
/// (comm/xlogger/preprocessor.h). The MSVC traditional preprocessor fails to
/// expand that chain and produces undefined identifiers like
/// `PP_IF_PP_BOOL_PP_DEC_PP_SIZE_` (C2143/C2146/C2059/C3861; verified with
/// MSVC 14.44 / VS2022 — a minimal repro with `xerror2(TSF "...", a, b)`
/// always fails with the traditional preprocessor and compiles cleanly with
/// `/Zc:preprocessor`). Upstream Windows CMake has no such option (it relies
/// on the old traditional-preprocessor behavior), so this is a local compile
/// fix. Companion patch: PP_SIZE in comm/xlogger/preprocessor.h takes the
/// standard implementation when `_MSVC_TRADITIONAL==0` (empty-variadic
/// counting in the traditional branch relies on the non-standard MSVC
/// comma-swallowing behavior).
///
/// Reason 2 (`/Zc:__cplusplus`): MSVC defaults to `__cplusplus=199711L`,
/// while the vendored mars sources contain `#if __cplusplus > 201103L`
/// (strutil.h L183, the to_string templates) and
/// `#if __cplusplus >= 201103L` (message_queue.h and others, move-semantics
/// branches). Without the flag, strutil::to_string stays hidden (http.cc
/// C2039) etc. Other compilers (clang/gcc) already use the real
/// `__cplusplus`; enabling it on Windows aligns behavior.
///
/// Application scope (per the 2026-11 static scan of the Windows source
/// lists):
/// - Hard requirement (some TU calls xlogger nested macros or
///   strutil::to_string; fails to compile without): comm1 (26/49 files call
///   macros, http.cc uses strutil::to_string), baseevent (active_logic.cc),
///   app (3/3), sdt (15/15), stn (29/31).
/// - Uniform defense (compiles today without, added for consistency across
///   all mars modules and safety against upstream drift): comm2 (pure C;
///   xloggerbase.c only defines the xlogger_Print C function), boot
///   (context.cc uses standard headers only), xlog1 (logging backend goes
///   through the xlogger_Print C interface; appender.cc includes strutil.h
///   but only uses its local to_string/std::to_string), xlog2 (pure C), the
///   mars bridge (mars.cpp has no macro calls and no gated headers in its
///   include tree). Note: /Zc:__cplusplus poses no real ODR risk (the
///   __cplusplus gate in message_queue.h guards BOOST_STATIC_ASSERT only and
///   never produces different function definitions).
/// - Not added: boost/zstd (do not include mars headers; the vendored old
///   boost is verified with /Zc:__cplusplus absent, and adding it would
///   activate unverified old-boost __cplusplus branches).
List<String> _getMsvcStandardPreprocessorFlags(OS targetOS) => [
  if (targetOS == .windows) ...['/Zc:preprocessor', '/Zc:__cplusplus'],
];

/// Upstream source: comm/utils.cmake.
///
/// - `XLOGGER_TAG="mars::<PROJECT_NAME>"` (L7, per-module projectName).
/// - MSVC platform macros (L28-32): `_WIN32 WIN32 UNICODE _UNICODE NOMINMAX
///   _LIB` (64-bit adds `_WIN64 WIN64`).
///
/// utils.cmake defines intentionally NOT duplicated here:
/// - Debug macros (MSVC /DDEBUG, non-MSVC -DDEBUG): native_toolchain_c's
///   `buildModeDefine: true` (default) defines DEBUG in debug builds
///   automatically; NDEBUG comes from `ndebugDefine: true`.
/// - Optional defines (off by default): UNITTEST / DISABLE_QUIC_PROTOCOL /
///   DISABLE_PCDN_PROTOCOL / CPP_CALL_BACK / NATIVE_CALLBACK /
///   USE_CPP_CALLBACK — the corresponding options are not enabled by these
///   hooks, so they stay off.
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

/// Local additions (upstream CMake platform defaults / local fixes).
///
/// - `ANDROID` / `_WINDOWS`: upstream CMake platform default macros, added
///   explicitly here.
/// - `__WIN32__`: intentional local addition (not in upstream).
Map<String, String?> _getCMakeDefines(OS targetOS) => {
  if (targetOS == .android) 'ANDROID': null,
  if (targetOS == .windows) ...{'_WINDOWS': null, '__WIN32__': null},
};

String? _getStd(OS targetOS) => switch (targetOS) {
  .android || .iOS || .macOS || .linux => 'gnu++14',
  .windows => null,
  _ => throw UnsupportedError('Unsupported os: $targetOS'),
};

/// Optimization level: native_toolchain_c's `optimizationLevel` (replaces -O
/// flags).
///
/// Mirrors upstream utils.cmake (release settings in effect). Returning `.o3`
/// is equivalent to omitting the parameter (`.o3` is the CBuilder.library
/// default, see clibrary.dart L104):
/// - Android: release → `.o3` (branch L69-70 has no -O = CMake default -O3);
///   debug → `.o0` (L54).
/// - Apple/Linux: release → `.oS` (L83-84 / L111-112); debug → `.o0`
///   (L85-86 / L54).
/// - Windows: always `.o3` (release = CMake default /O2; .o3 maps to /O2 on
///   MSVC, see optimization_level.dart `o3.msvcFlag()`; debug is also /O2 —
///   the difference from upstream's default /Od in debug is currently
///   accepted, release builds only).
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
