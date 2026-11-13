import 'mars_bindings_generated.dart' as ffi;

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
