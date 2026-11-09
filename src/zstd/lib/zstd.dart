/// Zstandard (zstd) compression and decompression.
///
/// Exposes a `dart:convert` `Codec` over the zstd library built from source by
/// this package's native assets build hooks.
///
/// ```dart
/// import 'dart:convert';
/// import 'package:zstd/zstd.dart';
///
/// void main() {
///   final input = utf8.encode('hello hello hello');
///   final compressed = zstd.encode(input);
///   print(zstd.decode(compressed));
/// }
/// ```
library;

export 'src/zstd.dart';
