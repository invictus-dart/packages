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

#include <stddef.h>
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

  // Generic byte buffer handle with a private struct layout (defined in
  // mars.cpp). Create with mars_create_buffer(); fill via library functions
  // (mars_xlog_decode, mars_write_buffer); read back with
  // mars_read_buffer(); release with mars_free_buffer(). The storage lives
  // in this library's C runtime (static /MT on Windows) and must never be
  // freed by the caller.
  typedef struct MarsBuffer MarsBuffer;

  // Create an empty buffer to be filled by library functions such as
  // mars_xlog_decode or by mars_write_buffer(). Returns NULL on allocation
  // failure.
  FFI_PLUGIN_EXPORT MarsBuffer *mars_create_buffer();

  // Free a MarsBuffer returned by mars_create_buffer(). NULL is a no-op.
  FFI_PLUGIN_EXPORT void mars_free_buffer(MarsBuffer *buffer);

  // Replace the buffer content with a copy of `size` bytes from `input`; any
  // previous content is released first, so the same buffer can be reused.
  // A size of 0 clears the buffer. Returns 0 on success; -1 when buffer is
  // NULL or input is NULL with a positive size; -2 on allocation failure.
  FFI_PLUGIN_EXPORT int mars_write_buffer(MarsBuffer *buffer, const char *input, size_t size);

  // Copy the buffer content into `output` (capacity `size` bytes). If
  // `output` is NULL or `size` is smaller than the content, nothing is
  // copied and the required size is returned (query pass); otherwise the
  // content is copied and its length returned. Returns 0 for a NULL or
  // empty buffer. The content is NOT NUL-terminated.
  FFI_PLUGIN_EXPORT size_t mars_read_buffer(const MarsBuffer *buffer, char *output, size_t size);

  // Open the xlog appender. Mirrors mars::xlog::appender_open(XLogConfig).
  //
  // All string parameters are UTF-8, may be NULL for empty.
  //   mode:           MarsAppenderMode
  //   logs_dir:        directory for log files
  //   cache_dir:      directory for cache files (may be same as logs_dir)
  //   cache_days:     days to keep cache files
  //   name_prefix:    prefix of log file names
  //   compress_mode:  MarsCompressMode
  //   compress_level: zlib/zstd compression level
  //   pub_key:        public key for log encryption (empty = no encryption)
  FFI_PLUGIN_EXPORT void mars_xlog_appender_open(int mode, const char *logs_dir, const char *cache_dir, int cache_days, const char *name_prefix, int compress_mode, int compress_level, const char *pub_key);

  // Close the xlog appender.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_close();

  // Flush buffered logs to disk (async).
  FFI_PLUGIN_EXPORT void mars_xlog_appender_flush();

  // Flush buffered logs to disk and wait for completion.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_flush_sync();

  // Enable/disable printing logs to console.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_console_log(int is_open);

  // Split log files when a single file exceeds max_byte_size (0 = no split).
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_max_file_size(uint64_t max_byte_size);

  // Max alive duration of a single log file in seconds.
  FFI_PLUGIN_EXPORT void mars_xlog_appender_set_max_alive_duration(int64_t max_time_seconds);

  // Get the current global log level.
  FFI_PLUGIN_EXPORT int mars_xlog_xlogger_level();

  // Set the global log level filter.
  FFI_PLUGIN_EXPORT void mars_xlog_xlogger_set_level(int level);

  // Whether messages of the given level will be logged.
  FFI_PLUGIN_EXPORT int mars_xlog_xlogger_is_enabled_for(int level);

  // Write a log message. Mirrors xlogger_Write with a filled XLoggerInfo.
  //   level:    MarsLogLevel
  //   tag:      log tag, may be NULL
  //   file_name: source file name, may be NULL
  //   line:     source line number
  //   func_name: source function name, may be NULL
  //   message:  log message (not NULL)
  FFI_PLUGIN_EXPORT void mars_xlog_xlogger_write(int level, const char *tag, const char *file_name, int line, const char *func_name, const char *message);

  // Decode an xlog log-file image to plaintext (adapted from the upstream
  // decode_log_file.c CLI; implementation: src/xlog/decode.c, full
  // contract: src/xlog/decode.h).
  //   input:    raw log file bytes (read-only, borrowed for the call only)
  //   size:     length of input in bytes
  //   buffer:   receives the decoded plaintext; must be a MarsBuffer from
  //             mars_create_buffer(). Read it back with mars_read_buffer().
  //             The buffer is valid on every return: it holds the decoded
  //             (or partially decoded) output on success and on -5/-6/-7,
  //             and keeps its previous content on -1/-2
  //   priv_key: server ECDH private key (64 hex chars), NULL = no key
  // Returns the decode status (negated upstream CLI exit codes):
  //    0  success
  //   -1  no valid log header found (not a failure); also when input is
  //       NULL, size is 0, or buffer is NULL
  //   -2  memory allocation failure
  //   -5  output buffer realloc failure
  //   -6  zlib/zstd decompression failure
  //   -7  priv_key is not NULL but malformed
  // Logs may be partially encrypted: with priv_key NULL an ECDH-encrypted
  // segment is skipped with a "Get ECDH key error" placeholder and decoding
  // continues with the unencrypted parts.
  FFI_PLUGIN_EXPORT int mars_xlog_decode(const char *input, size_t size, MarsBuffer *buffer, const char *priv_key);

#ifdef __cplusplus
}
#endif

#endif // MARS_FFI_BRIDGE_H
