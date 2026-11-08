// Dart API for the Mars XLog logger (Tencent/Mars).
//
// Thin wrapper over the FFI bridge in `src/mars.h`; bindings in
// `lib/src/mars_bindings_generated.dart` (ffigen-generated).

import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:stack_trace/stack_trace.dart';

import 'mars_bindings_generated.dart' as ffi;

/// The shared [Xlog] instance.
///
/// Initialized lazily on first access; every access returns the same object
/// within the current isolate.
Xlog get xlog => Xlog._instance;

/// Appender mode, mirrors `mars::xlog::TAppenderMode`.
enum AppenderMode {
  async(.kMarsAppenderAsync),
  sync(.kMarsAppenderSync);

  final ffi.MarsAppenderMode _mode;

  const AppenderMode(this._mode);

  /// The underlying native enum value.
  int get value => _mode.value;
}

/// Compress mode, mirrors `mars::xlog::TCompressMode`.
enum CompressMode {
  zlib(.kMarsCompressZlib),
  zstd(.kMarsCompressZstd);

  final ffi.MarsCompressMode _mode;

  const CompressMode(this._mode);

  /// The underlying native enum value.
  int get value => _mode.value;
}

/// Compression level for log files, 1 (fastest) to 9 (smallest output).
///
/// Valid for both [CompressMode.zlib] and [CompressMode.zstd]; the default
/// [CompressLevel.level6] matches upstream Mars.
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

  /// The underlying native enum value.
  int get value => _level.value;
}

/// Mars XLog logger.
///
/// Usage: call [open] once at startup, log with the level helpers
/// ([verbose] … [fatal]), then [close] before process exit so buffered
/// logs are flushed to disk.
///
/// ```dart
/// xlog.open(logsDir: dir, cacheDir: dir);
/// xlog.info('MyTag', 'hello');
/// xlog.close();
/// ```
abstract base class Xlog {
  static final Xlog _instance = _XlogImpl();

  /// Only implemented inside this library; use the top-level [xlog] getter.
  Xlog.impl();

  /// Opens the xlog appender and sets the global log level.
  ///
  /// Must be called once before any logging.
  ///
  /// - [mode]: [AppenderMode.async] buffers logs and flushes periodically
  ///   (recommended); [AppenderMode.sync] writes on every log call (slower,
  ///   useful while debugging).
  /// - [level]: global level filter; messages below it are dropped.
  /// - [logsDir]: directory for final log files.
  /// - [cacheDir]: directory for cached logs (may be the same as [logsDir]).
  /// - [cacheDays]: days to keep cached files (0 = no expiry).
  /// - [namePrefix]: prefix of log file names.
  /// - [compressMode] / [compressLevel]: log compression.
  /// - [pubKey]: ECDH public key for log encryption (null = no encryption).
  /// - [useConsole]: also print logs to the console.
  /// - [maxFileSize]: rotate to a new file above this size in bytes
  ///   (0 = unlimited).
  /// - [maxAliveDuration]: seconds a log file stays alive before rotation
  ///   (default 10 days).
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

  /// Asks the appender thread to write out buffered logs; returns
  /// immediately, without waiting for the write to finish.
  ///
  /// Use [flushSync] when logs must already be on disk at a given point.
  void flush();

  /// Flushes buffered logs to disk, waiting until they are written.
  ///
  /// The blocking flush (compression and file write) runs on a helper
  /// isolate, so `await`-ing it does not block the UI isolate. Logs written
  /// concurrently from other code may or may not make it into this flush
  /// snapshot; see [flush] for the non-blocking variant.
  Future<void> flushSync();

  /// Closes the appender and merges cached logs into the final log files.
  ///
  /// Call before process exit to avoid losing buffered logs. The appender
  /// can be reopened afterwards with [open].
  void close();

  /// Writes one log entry at [level], tagged with [tag].
  ///
  /// Dropped when [level] is below the global level set in [open].
  void write(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]);

  /// Logs at verbose level.
  void verbose(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.verbose, tag, message, error, stackTrace);

  /// Logs at debug level.
  void debug(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.debug, tag, message, error, stackTrace);

  /// Logs at info level.
  void info(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.info, tag, message, error, stackTrace);

  /// Logs at warn level.
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.warn, tag, message, error, stackTrace);

  /// Logs at error level.
  void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.error, tag, message, error, stackTrace);

  /// Logs at fatal level.
  void fatal(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => write(.fatal, tag, message, error, stackTrace);

  /// Decodes a raw xlog log-file image back to plaintext.
  ///
  /// [input] is the byte content of a log file produced by [open] logging.
  /// [privKey] is the server ECDH private key (64 hex chars); when null,
  /// ECDH-encrypted segments are skipped with a placeholder and only the
  /// unencrypted parts are decoded.
  ///
  /// Runs on a helper isolate. Returns the decoded plaintext bytes; throws
  /// [StateError] when decoding fails.
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
  }) => ffi.using((arena) {
    ffi.mars_xlog_xlogger_set_level(level.value);
    ffi.mars_xlog_appender_set_console_log(useConsole ? 1 : 0);
    ffi.mars_xlog_appender_set_max_file_size(maxFileSize);
    ffi.mars_xlog_appender_set_max_alive_duration(maxAliveDuration);
    ffi.mars_xlog_appender_open(
      mode.value,
      logsDir.toNativeUtf8(allocator: arena).cast(),
      cacheDir.toNativeUtf8(allocator: arena).cast(),
      cacheDays,
      namePrefix?.toNativeUtf8(allocator: arena).cast() ?? ffi.nullptr,
      compressMode.value,
      compressLevel.value,
      pubKey?.toNativeUtf8(allocator: arena).cast() ?? ffi.nullptr,
    );
  });

  @override
  void flush() => ffi.mars_xlog_appender_flush();

  @override
  Future<void> flushSync() =>
      Isolate.run(() => ffi.mars_xlog_appender_flush_sync());

  @override
  void close() => ffi.mars_xlog_appender_close();

  @override
  void write(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => ffi.using((arena) {
    final isEnabled = ffi.mars_xlog_xlogger_is_enabled_for(level.value) != 0;
    if (!isEnabled) return;
    final trace = stackTrace == null ? null : Trace.from(stackTrace);
    final frame = trace?.frames.firstOrNull;
    final fileName = frame?.uri.pathSegments.last;
    final line = frame?.line;
    final member = frame?.member;
    final messageBuffer = StringBuffer(message);
    if (error != null) {
      messageBuffer.writeln();
      messageBuffer.write(error);
    }
    if (trace != null) {
      messageBuffer.writeln();
      messageBuffer.write(trace.terse);
    }
    ffi.mars_xlog_xlogger_write(
      level.value,
      tag.toNativeUtf8(allocator: arena).cast(),
      fileName?.toNativeUtf8(allocator: arena).cast() ?? ffi.nullptr,
      line ?? 0,
      member?.toNativeUtf8(allocator: arena).cast() ?? ffi.nullptr,
      messageBuffer.toString().toNativeUtf8(allocator: arena).cast(),
    );
  });

  @override
  Future<Uint8List> decode(Uint8List input, {String? privKey}) => Isolate.run(
    () => ffi.using((arena) {
      final inputPtr = arena<ffi.Uint8>(input.length);
      inputPtr.asTypedList(input.length).setAll(0, input);
      final bufferPtr = ffi.mars_create_buffer();
      try {
        final statusCode = ffi.mars_xlog_decode(
          inputPtr.cast(),
          input.length,
          bufferPtr,
          privKey?.toNativeUtf8().cast() ?? ffi.nullptr,
        );
        if (statusCode != 0) throw StateError('decode failed: $statusCode');
        final expectedSize = ffi.mars_read_buffer(bufferPtr, ffi.nullptr, 0);
        final outputPtr = arena<ffi.Uint8>(expectedSize);
        final actualSize = ffi.mars_read_buffer(
          bufferPtr,
          outputPtr.cast(),
          expectedSize,
        );
        if (actualSize != expectedSize) {
          throw StateError('decode failed: $actualSize/$expectedSize');
        }
        final output = outputPtr.asTypedList(expectedSize);
        return Uint8List.fromList(output);
      } finally {
        ffi.mars_free_buffer(bufferPtr);
      }
    }),
  );
}
