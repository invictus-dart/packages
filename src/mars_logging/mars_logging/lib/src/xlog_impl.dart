import 'package:mars_logging_api/mars_logging_api.dart';

import 'mars_logging_api.g.dart';

final class XLogImpl extends XLogApi {
  final XLogHostApi _api;

  XLogImpl.internal(this._api) : super.impl();

  factory XLogImpl() {
    final api = XLogHostApi();
    return XLogImpl.internal(api);
  }

  @override
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
  ) => _api.open(
    mode.api,
    level.api,
    logsDir,
    cacheDir,
    cacheDays,
    namePrefix,
    compressMode.api,
    compressLevel.api,
    pubKey,
    useConsole,
    maxFileSize,
    maxAliveDuration,
  );

  @override
  Future<void> flush(bool isSync) => _api.flush(isSync);

  @override
  Future<void> close() => _api.close();

  @override
  Future<void> verbose(String tag, String message) =>
      _api.verbose(tag, message);

  @override
  Future<void> debug(String tag, String message) => _api.debug(tag, message);

  @override
  Future<void> info(String tag, String message) => _api.info(tag, message);

  @override
  Future<void> warning(String tag, String message) =>
      _api.warning(tag, message);

  @override
  Future<void> error(String tag, String message) => _api.error(tag, message);

  @override
  Future<void> fatal(String tag, String message) => _api.fatal(tag, message);
}

extension on AppenderMode {
  AppenderModeApi get api {
    switch (this) {
      case AppenderMode.async:
        return AppenderModeApi.async;
      case AppenderMode.sync:
        return AppenderModeApi.sync;
    }
  }
}

extension on XLogLevel {
  XLogLevelApi get api {
    switch (this) {
      case XLogLevel.all:
        return XLogLevelApi.all;
      case XLogLevel.verbose:
        return XLogLevelApi.verbose;
      case XLogLevel.debug:
        return XLogLevelApi.debug;
      case XLogLevel.info:
        return XLogLevelApi.info;
      case XLogLevel.warning:
        return XLogLevelApi.warning;
      case XLogLevel.error:
        return XLogLevelApi.error;
      case XLogLevel.fatal:
        return XLogLevelApi.fatal;
      case XLogLevel.none:
        return XLogLevelApi.none;
    }
  }
}

extension on CompressMode {
  CompressModeApi get api {
    switch (this) {
      case CompressMode.zlib:
        return CompressModeApi.zlib;
      case CompressMode.zstd:
        return CompressModeApi.zstd;
    }
  }
}

extension on CompressLevel {
  CompressLevelApi get api {
    switch (this) {
      case CompressLevel.level1:
        return CompressLevelApi.level1;
      case CompressLevel.level2:
        return CompressLevelApi.level2;
      case CompressLevel.level3:
        return CompressLevelApi.level3;
      case CompressLevel.level4:
        return CompressLevelApi.level4;
      case CompressLevel.level5:
        return CompressLevelApi.level5;
      case CompressLevel.level6:
        return CompressLevelApi.level6;
      case CompressLevel.level7:
        return CompressLevelApi.level7;
      case CompressLevel.level8:
        return CompressLevelApi.level8;
      case CompressLevel.level9:
        return CompressLevelApi.level9;
    }
  }
}
