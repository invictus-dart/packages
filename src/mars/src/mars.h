// Mars FFI bridge - C API surface for Dart bindings.
//
// This header is the bridge between Dart (via ffigen-generated bindings) and
// the Mars C++ SDK. It mirrors the official Mars public API
// (mars/comm/xlogger/xloggerbase.h, mars/xlog/appender.h) with a stable
// C ABI that ffigen can parse. Implementation lives in mars.cpp.
//
// Generated bindings are regenerated with `dart run tool/ffigen.dart`.

#ifndef MARS_FFI_BRIDGE_H
#define MARS_FFI_BRIDGE_H

#include <stdint.h>

#ifdef _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C"
{
#endif

  // Log levels, mirrors mars::TLogLevel (mars/comm/xlogger/xloggerbase.h).
  typedef enum MarsLogLevel
  {
    kMarsLogLevelAll = 0,
    kMarsLogLevelVerbose = 0,
    kMarsLogLevelDebug = 1,
    kMarsLogLevelInfo = 2,
    kMarsLogLevelWarn = 3,
    kMarsLogLevelError = 4,
    kMarsLogLevelFatal = 5,
    kMarsLogLevelNone = 6,
  } MarsLogLevel;

  // Appender mode, mirrors mars::xlog::TAppenderMode.
  typedef enum MarsAppenderMode
  {
    kMarsAppenderAsync = 0,
    kMarsAppenderSync = 1,
  } MarsAppenderMode;

  // Compress mode, mirrors mars::xlog::TCompressMode.
  typedef enum MarsCompressMode
  {
    kMarsCompressZlib = 0,
    kMarsCompressZstd = 1,
  } MarsCompressMode;

  // Open the xlog appender. Mirrors mars::xlog::appender_open(XLogConfig).
  //
  // All string parameters are UTF-8, may be NULL for empty.
  //   mode:           MarsAppenderMode
  //   log_dir:        directory for log files
  //   name_prefix:    prefix of log file names
  //   pub_key:        public key for log encryption (empty = no encryption)
  //   compress_mode:  MarsCompressMode
  //   compress_level: zlib/zstd compression level
  //   cache_dir:      directory for cache files (may be same as log_dir)
  //   cache_days:     days to keep cache files
  FFI_PLUGIN_EXPORT void mars_xlog_appender_open(int mode, const char *log_dir, const char *name_prefix, const char *pub_key, int compress_mode, int compress_level, const char *cache_dir, int cache_days);

  // Close the xlog appender.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_close(void);

  // Flush buffered logs to disk (async).
  FFI_PLUGIN_EXPORT void mars_xlog_appender_flush(void);

  // Flush buffered logs to disk and wait for completion.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_flush_sync(void);

  // Enable/disable printing logs to console.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_console_log(int is_open);

  // Split log files when a single file exceeds max_byte_size (0 = no split).
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_max_file_size(uint64_t max_byte_size);

  // Max alive duration of a single log file in seconds.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_max_alive_duration(int64_t max_time_seconds);

  // Get the current global log level.
  FFI_PLUGIN_EXPORT int mars_xlog_xlogger_level(void);

  // Set the global log level filter.
  FFI_PLUGIN_EXPORT void mars_xlog_xlogger_set_level(int level);

  // Whether messages of the given level will be logged.
  FFI_PLUGIN_EXPORT int mars_xlog_xlogger_is_enabled_for(int level);

  // Write a log message. Mirrors xlogger_Write with a filled XLoggerInfo.
  //   level:    MarsLogLevel
  //   tag:      log tag, may be NULL
  //   filename: source file name, may be NULL
  //   line:     source line number
  //   content:  log content (not NULL)
  FFI_PLUGIN_EXPORT void mars_xlog_xlogger_write(int level, const char *tag, const char *filename, int line, const char *content);

#ifdef __cplusplus
}
#endif

#endif // MARS_FFI_BRIDGE_H
