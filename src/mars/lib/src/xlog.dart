// Dart API for the Mars SDK (Tencent/Mars) FFI bridge.
//
// Exposes the XLog logging functionality of Mars through the C bridge in
// `src/mars.h` (bindings in `mars_bindings_generated.dart`).

import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;

import 'mars.g.dart' as ffi;

/// Appender mode, mirrors `mars::xlog::TAppenderMode`.
enum AppenderMode {
  async(.kMarsAppenderAsync),
  sync(.kMarsAppenderSync);

  final ffi.MarsAppenderMode _mode;

  const AppenderMode(this._mode);

  int get value => _mode.value;
}

/// Compress mode, mirrors `mars::xlog::TCompressMode`.
enum CompressMode {
  zlib(.kMarsCompressZlib),
  zstd(.kMarsCompressZstd);

  final ffi.MarsCompressMode _mode;

  const CompressMode(this._mode);

  int get value => _mode.value;
}

enum CompressLevel {
  level1(1),
  level2(2),
  level3(3),
  level4(4),
  level5(5),
  level6(6),
  level7(7),
  level8(8),
  level9(9);

  final int value;

  const CompressLevel(this.value);
}

/// Log levels, mirrors `mars::TLogLevel`.
enum LogLevel {
  all(.kMarsLogLevelAll),
  verbose(.kMarsLogLevelVerbose),
  debug(.kMarsLogLevelDebug),
  info(.kMarsLogLevelInfo),
  warn(.kMarsLogLevelWarn),
  error(.kMarsLogLevelError),
  fatal(.kMarsLogLevelFatal),
  none(.kMarsLogLevelNone);

  final ffi.MarsLogLevel _level;

  const LogLevel(this._level);

  int get value => _level.value;
}

abstract base class Xlog {
  static Xlog? _instance;

  static Xlog get instance {
    var instance = _instance;
    if (instance == null) _instance = instance = _XlogImpl();
    return instance;
  }

  Xlog.impl();

  void open({
    AppenderMode mode = .async,
    LogLevel level = .all,
    required String logsDir,
    required String cacheDir,
    int cacheDays = 0,
    String? namePrefix,
    CompressMode compressMode = CompressMode.zlib,
    CompressLevel compressLevel = CompressLevel.level6,
    String? pubKey,
    bool useConsole = false,
    int maxFileSize = 0,
    int maxAliveDuration = 10 * 24 * 60 * 60,
  });

  void flush(bool isSync);

  void close();

  void write(LogLevel level, String tag, String message);

  void verbose(String tag, String message) => write(.verbose, tag, message);

  void debug(String tag, String message) => write(.debug, tag, message);

  void info(String tag, String message) => write(.info, tag, message);

  void warning(String tag, String message) => write(.warn, tag, message);

  void error(String tag, String message) => write(.error, tag, message);

  void fatal(String tag, String message) => write(.fatal, tag, message);

  Future<Uint8List> decode(Uint8List input, {String? privKey});
}

final class _XlogImpl extends Xlog {
  _XlogImpl() : super.impl();

  @override
  void open({
    AppenderMode mode = .async,
    LogLevel level = .all,
    required String logsDir,
    required String cacheDir,
    int cacheDays = 0,
    String? namePrefix,
    CompressMode compressMode = CompressMode.zlib,
    CompressLevel compressLevel = CompressLevel.level6,
    String? pubKey,
    bool useConsole = false,
    int maxFileSize = 0,
    int maxAliveDuration = 10 * 24 * 60 * 60,
  }) {
    ffi.mars_xlog_xlogger_set_level(level.value);
    ffi.mars_xlog_appender_set_console_log(useConsole ? 1 : 0);
    ffi.mars_xlog_appender_set_max_file_size(maxFileSize);
    ffi.mars_xlog_appender_set_max_alive_duration(maxAliveDuration);
    ffi.mars_xlog_appender_open(
      mode.value,
      logsDir.toNativeUtf8().cast(),
      cacheDir.toNativeUtf8().cast(),
      cacheDays,
      namePrefix?.toNativeUtf8().cast() ?? ffi.nullptr,
      compressMode.value,
      compressLevel.value,
      pubKey?.toNativeUtf8().cast() ?? ffi.nullptr,
    );
  }

  @override
  void flush(bool isSync) => isSync
      ? ffi.mars_xlog_appender_flush_sync()
      : ffi.mars_xlog_appender_flush();

  @override
  void close() => ffi.mars_xlog_appender_close();

  @override
  void write(LogLevel level, String tag, String message) {
    final isEnabled = ffi.mars_xlog_xlogger_is_enabled_for(level.value) != 0;
    if (!isEnabled) return;
    ffi.mars_xlog_xlogger_write(
      level.value,
      tag.toNativeUtf8().cast(),
      ffi.nullptr,
      0,
      ffi.nullptr,
      message.toNativeUtf8().cast(),
    );
  }

  @override
  Future<Uint8List> decode(Uint8List input, {String? privKey}) => Isolate.run(
    () => ffi.using((arena) {
      final inputPtr = arena<ffi.Uint8>(input.length);
      inputPtr.asTypedList(input.length).setAll(0, input);
      final bufferPtr = ffi.mars_create_buffer();
      try {
        var statusCode = ffi.mars_xlog_decode(
          inputPtr.cast(),
          input.length,
          bufferPtr,
          privKey?.toNativeUtf8().cast() ?? ffi.nullptr,
        );
        if (statusCode != 0) throw StateError('decode failed: $statusCode');
        final size = ffi.mars_read_buffer(bufferPtr, ffi.nullptr, 0);
        if (size < 0) throw StateError('decode failed: $size');
        final outputPtr = arena<ffi.Uint8>(size);
        statusCode = ffi.mars_read_buffer(bufferPtr, outputPtr.cast(), size);
        if (statusCode != 0) throw StateError('decode failed: $statusCode');
        return outputPtr.asTypedList(size);
      } finally {
        ffi.mars_free_buffer(bufferPtr);
      }
    }),
  );
}
