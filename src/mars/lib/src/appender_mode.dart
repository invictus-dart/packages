import 'mars_bindings_generated.dart' as ffi;

/// Appender mode, mirrors `mars::xlog::TAppenderMode`.
enum AppenderMode {
  async(.kMarsAppenderAsync),
  sync(.kMarsAppenderSync);

  final ffi.MarsAppenderMode _mode;

  const AppenderMode(this._mode);

  /// The underlying native enum value.
  int get value => _mode.value;
}
