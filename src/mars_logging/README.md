# mars_logging

[![pub package](https://img.shields.io/pub/v/mars_logging.svg)](https://pub.dev/packages/mars_logging)

An integration which adds support for recording logs from the
[`logging`](https://pub.dev/packages/logging) package into
[Mars](https://pub.dev/packages/mars) XLog.

## Status: Experimental

**NOTE**: This package is published as a development prerelease
(`1.0.0-dev.4`) to solicit feedback. The API surface is expected to change —
potentially in breaking ways — before the stable `1.0.0` release.

## Usage

Attach the integration once, typically at startup:

```dart
import 'package:logging/logging.dart';
import 'package:mars_logging/mars_logging.dart';

void main() {
  xlog.open(
    logsDir: '/path/to/logs',
    cacheDir: '/path/to/logs/cache',
  );
  Logger.root.onRecord.listen(xlog.onRecord);

  Logger('MyApp').info('hello');
  Logger('MyApp').severe('something failed', error, stackTrace);

  xlog.close();
}
```

### Level mapping

`package:logging` levels map to Mars log levels as:

| `package:logging` | Mars XLog |
| --- | --- |
| `ALL` / `FINEST` / `FINER` / `FINE` | `verbose` |
| `CONFIG` | `debug` |
| `INFO` | `info` |
| `WARNING` | `warn` |
| `SEVERE` | `error` |
| `SHOUT` | `fatal` |

A record's `loggerName` becomes the xlog tag; `error` and `stackTrace`, when
present, are appended to the message.

See the [mars package](https://pub.dev/packages/mars) README for XLog
configuration (compression, encryption, rotation), flushing, and offline
decoding. A complete runnable example is available in
[`example/mars_logging_example.dart`](example/mars_logging_example.dart).

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).
