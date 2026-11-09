import 'package:logging/logging.dart';
import 'package:mars/mars.dart';

/// Bridges `package:logging` records to [Xlog].
///
/// Attach it once, typically at startup:
///
/// ```dart
/// Logger.root.level = Level.ALL;
/// Logger.root.onRecord.listen(xlog.onRecord);
/// ```
extension XlogIntegrationExt on Xlog {
  /// Writes [record] as one xlog entry.
  ///
  /// The record's `loggerName` becomes the xlog tag; [Level] maps to
  /// [LogLevel] ascending as FINE/FINER/FINEST → verbose, CONFIG → debug,
  /// INFO → info, WARNING → warn, SEVERE → error, SHOUT → fatal.
  /// `error` and `stackTrace`, when present, are appended to the message.
  void onRecord(LogRecord record) {
    final level = switch (record.level) {
      < .CONFIG => LogLevel.verbose,
      < .INFO => LogLevel.debug,
      < .WARNING => LogLevel.info,
      < .SEVERE => LogLevel.warn,
      < .SHOUT => LogLevel.error,
      _ => LogLevel.fatal,
    };
    final tag = record.loggerName;
    final message = record.message;
    final error = record.error;
    final stackTrace = record.stackTrace;
    write(level, tag, message, error, stackTrace);
  }
}
