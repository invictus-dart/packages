// Dart API for the Mars SDK (Tencent/Mars) FFI bridge.
//
// Exposes the XLog logging functionality of Mars through the C bridge in
// `src/mars.h` (bindings in `mars_bindings_generated.dart`).

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'mars_bindings_generated.dart' as bindings;

/// Log levels, mirrors `mars::TLogLevel`.
enum MarsLogLevel {
  all(0),
  debug(1),
  info(2),
  warn(3),
  error(4),
  fatal(5),
  none(6);

  final int value;

  const MarsLogLevel(this.value);
}

/// Appender mode, mirrors `mars::xlog::TAppenderMode`.
enum MarsAppenderMode {
  async(0),
  sync(1);

  final int value;

  const MarsAppenderMode(this.value);
}

/// Compress mode, mirrors `mars::xlog::TCompressMode`.
enum MarsCompressMode {
  zlib(0),
  zstd(1);

  final int value;

  const MarsCompressMode(this.value);
}

/// Configuration for [xlogOpen], mirrors `mars::xlog::XLogConfig`.
class XLogConfig {
  final MarsAppenderMode mode;
  final String logDir;
  final String namePrefix;
  final String pubKey;
  final MarsCompressMode compressMode;
  final int compressLevel;
  final String cacheDir;
  final int cacheDays;

  const XLogConfig({
    this.mode = MarsAppenderMode.async,
    required this.logDir,
    required this.namePrefix,
    this.pubKey = '',
    this.compressMode = MarsCompressMode.zlib,
    this.compressLevel = 6,
    this.cacheDir = '',
    this.cacheDays = 0,
  });
}

/// Open the xlog appender. See [XLogConfig].
void xlogOpen(XLogConfig config) {
  final logDir = config.logDir.toNativeUtf8().cast<Char>();
  final namePrefix = config.namePrefix.toNativeUtf8().cast<Char>();
  final pubKey = config.pubKey.toNativeUtf8().cast<Char>();
  final cacheDir = config.cacheDir.toNativeUtf8().cast<Char>();
  try {
    bindings.mars_xlog_appender_open(
      config.mode.value,
      logDir,
      namePrefix,
      pubKey,
      config.compressMode.value,
      config.compressLevel,
      cacheDir,
      config.cacheDays,
    );
  } finally {
    malloc.free(logDir);
    malloc.free(namePrefix);
    malloc.free(pubKey);
    malloc.free(cacheDir);
  }
}

/// Close the xlog appender.
void xlogClose() => bindings.mars_xlog_appender_close();

/// Flush buffered logs to disk (async).
void xlogFlush() => bindings.mars_xlog_appender_flush();

/// Flush buffered logs to disk and wait for completion.
void xlogFlushSync() => bindings.mars_xlog_appender_flush_sync();

/// Enable/disable printing logs to the console.
void xlogSetConsoleLog({bool open = true}) =>
    bindings.mars_xlog_appender_set_console_log(open ? 1 : 0);

/// Split log files when a single file exceeds [maxByteSize] (0 = no split).
void xlogSetMaxFileSize(int maxByteSize) =>
    bindings.mars_xlog_appender_set_max_file_size(maxByteSize);

/// Max alive duration of a single log file in seconds.
void xlogSetMaxAliveDuration(int maxTimeSeconds) =>
    bindings.mars_xlog_appender_set_max_alive_duration(maxTimeSeconds);

/// Write a log message.
///
/// [tag] and [filename] may be null.
void xlogWrite(MarsLogLevel level, String? tag, String? filename, int line,
    String content) {
  final tagPtr = tag?.toNativeUtf8().cast<Char>() ?? nullptr;
  final filenamePtr = filename?.toNativeUtf8().cast<Char>() ?? nullptr;
  final contentPtr = content.toNativeUtf8().cast<Char>();
  try {
    bindings.mars_xlog_xlogger_write(
      level.value,
      tagPtr,
      filenamePtr,
      line,
      contentPtr,
    );
  } finally {
    if (tagPtr != nullptr) malloc.free(tagPtr);
    if (filenamePtr != nullptr) malloc.free(filenamePtr);
    malloc.free(contentPtr);
  }
}

/// Set the global log level filter.
void xlogSetLevel(MarsLogLevel level) =>
    bindings.mars_xlog_xlogger_set_level(level.value);

/// Get the current global log level.
MarsLogLevel xlogGetLevel() =>
    MarsLogLevel.values[bindings.mars_xlog_xlogger_level()];

/// Whether messages of the given [level] will be logged.
bool xlogIsEnabled(MarsLogLevel level) =>
    bindings.mars_xlog_xlogger_is_enabled_for(level.value) != 0;
