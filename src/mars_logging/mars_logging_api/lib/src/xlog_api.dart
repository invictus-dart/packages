import 'package:plugin_platform_interface/plugin_platform_interface.dart';

enum AppenderMode { async, sync }

enum XLogLevel { all, verbose, debug, info, warning, error, fatal, none }

enum CompressMode { zlib, zstd }

enum CompressLevel {
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
  level9,
}

abstract base class XLogApi extends PlatformInterface {
  static final Object _token = Object();

  static XLogApi? _instance;

  /// The default instance of [XLogApi] to use.
  static XLogApi get instance {
    final instance = _instance;
    if (instance == null) {
      throw UnimplementedError('XLogApi is not implemented');
    }
    return instance;
  }

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [XLogApi] when they register
  /// themselves.
  static set instance(XLogApi instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Constructs a MarsLoggingPlugin.
  XLogApi.impl() : super(token: _token);

  Future<void> open(
    AppenderMode mode,
    XLogLevel level,
    String logsDir,
    String cacheDir,
    int cacheDays,
    String namePrefix,
    CompressMode compressMode,
    CompressLevel compressLevel,
    String pubKey,
    bool useConsole,
    int maxFileSize,
    int maxAliveDuration,
  );
  Future<void> flush(bool isSync);
  Future<void> close();
  Future<void> verbose(String tag, String message);
  Future<void> debug(String tag, String message);
  Future<void> info(String tag, String message);
  Future<void> warning(String tag, String message);
  Future<void> error(String tag, String message);
  Future<void> fatal(String tag, String message);
}
