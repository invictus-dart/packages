/// `package:logging` integration for
/// [Mars](https://pub.dev/packages/mars).
///
/// Adds the `xlog.onRecord` extension member (`XlogIntegrationExt.onRecord`),
/// which forwards `package:logging` records to the Mars XLog logger.
///
/// This package does **not** re-export the Mars API — import `package:mars`
/// alongside it to use the XLog logger directly:
///
/// ```dart
/// import 'package:logging/logging.dart';
/// import 'package:mars/mars.dart';
/// import 'package:mars_logging/mars_logging.dart';
///
/// void main() {
///   xlog.open(logsDir: '/logs', cacheDir: '/logs/cache');
///   Logger.root.onRecord.listen(xlog.onRecord);
///
///   Logger('MyApp').info('hello');
///
///   xlog.close();
/// }
/// ```
library;

export 'src/xlog.dart';
