/// `package:logging` integration for
/// [Mars](https://pub.dev/packages/mars).
///
/// Exports the Mars XLog API and adds the `xlog.onRecord` extension member
/// (`XlogIntegrationExt.onRecord`), which forwards `package:logging`
/// records to the XLog logger.
///
/// ```dart
/// import 'package:logging/logging.dart';
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

export 'package:mars/mars.dart';

export 'src/xlog.dart';
