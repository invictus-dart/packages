import 'mars_bindings_generated.dart' as ffi;

/// Compress mode, mirrors `mars::xlog::TCompressMode`.
enum CompressMode {
  zlib(.kMarsCompressZlib),
  zstd(.kMarsCompressZstd);

  final ffi.MarsCompressMode _mode;

  const CompressMode(this._mode);

  /// The underlying native enum value.
  int get value => _mode.value;
}
