/// Dart bindings for [Mars](https://github.com/Tencent/mars), the
/// cross-platform component library developed by WeChat.
///
/// The native library is compiled from vendored Tencent/mars sources by the
/// native assets build hooks (`hook/build.dart` / `hook/link.dart`) when the
/// consuming application builds; no manual build steps are required.
///
/// Currently exposes:
///
/// - **XLog** — Mars' high-performance logging component, available through
///   the shared [xlog] instance.
///
/// Other Mars modules (STN networking, SDT, Comm) are compiled into the
/// library but not yet bridged to Dart.
///
/// ```dart
/// import 'package:mars/mars.dart';
///
/// void main() {
///   xlog.open(logsDir: '/logs', cacheDir: '/logs/cache');
///   xlog.info('MyTag', 'hello');
///   xlog.close();
/// }
/// ```
library;

export 'src/xlog.dart';
