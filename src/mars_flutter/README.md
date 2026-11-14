# mars_flutter

[![pub package](https://img.shields.io/pub/v/mars_flutter.svg)](https://pub.dev/packages/mars_flutter)

[Tencent/mars](https://github.com/Tencent/mars) for Flutter, The Dart API is re-exported from 
[mars](https://pub.dev/packages/mars), and the native APIs share the same library.

- Android binds the C ABI with JNA; no Tencent Java/JNI wrapper is required.
- iOS/macOS load Flutter's bundled `mars.framework` with `dlopen`/`dlsym`.
- Dart and native code share the same Mars library and component instances.

## Status: Experimental

**NOTE**: This package is published as a development prerelease
(`1.0.0-dev.0`) to solicit feedback. The API surface is expected to change —
potentially in breaking ways — before the stable `1.0.0` release.

Currently XLog is the only bridged component; bindings for the other Mars
modules (STN networking, SDT, Comm) will follow. Native Windows and Linux APIs
are planned as well — until then, use the Dart API on those platforms.

## Supported platforms

| Platform | Dart API | Native API |
| --- | :---: | :---: |
| Android | ✓ | ✓ (JNA, Kotlin) |
| iOS | ✓ | ✓ (dlopen, Swift) |
| macOS | ✓ | ✓ (dlopen, Swift) |
| Windows | ✓ | — |
| Linux | ✓ | — |

On Windows and Linux use the Dart API, which is served by the `mars` package's
native assets build hooks; native APIs for these platforms are planned.

## Installation

```yaml
dependencies:
  mars_flutter: ^1.0.0-dev.0
```

The native Mars library is compiled from source when your app builds, through
the native assets build hooks of the `mars` package. The C/C++ toolchain and
build tools for each target platform are therefore required — see the
[`mars` package README](../mars) for the full list (Android NDK, Xcode, Visual
Studio, Perl, NASM, `jom` on Windows, `make`, `tar`, `cmake`).

## Usage

### Dart

The Dart API is identical to [`package:mars`](../mars) — open the logger at
startup, log through the shared `xlog` instance, and flush or close before
exit:

```dart
import 'package:mars_flutter/mars_flutter.dart';

void main() async {
  xlog.open(
    mode: .async, // buffered, recommended
    level: .debug,
    logsDir: '/path/to/logs',
    cacheDir: '/path/to/cache',
    namePrefix: 'log',
    compressMode: .zstd,
    // pubKey: '<64 hex chars>', // ECDH public key to encrypt logs
  );

  xlog.info('MyTag', 'hello');
  xlog.error('MyTag', 'something failed', error, stackTrace);

  await xlog.flush(); // wait until buffered logs are on disk
  xlog.close();       // merge cached logs into final files
}
```

Decoding a log file back to plaintext works offline:

```dart
import 'dart:io';

import 'package:mars_flutter/mars_flutter.dart';

final input = await file.readAsBytes();
final output = await xlog.decode(input); // add privKey: for encrypted segments
final text = utf8.decode(output);
```

`XlogView` is a widget that decodes a `.xlog` file and renders the decoded lines:

```dart
XlogView(
  filePath: filePath,
  privKey: '<64 hex chars>', // optional, for encrypted segments
  padding: EdgeInsets.all(16),
  style: TextStyle(fontSize: 12),
  loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
  emptyBuilder: (context) => const Center(child: Text('No logs')),
)
```

It reloads when `filePath` or `privKey` changes.

### Android

```kotlin
import dev.invictus_dart.mars_flutter.xlog

xlog.open(logsDir = logsDir, cacheDir = cacheDir)
xlog.info("NativeTag", "hello from Android")
xlog.flush() // suspending — call from a coroutine scope
xlog.close()
```

`flush()` and `decode()` are suspending functions and run their blocking work
on `Dispatchers.IO`; `flushSync()` and `decodeSync()` block the calling thread.

### iOS/macOS

```swift
import mars_flutter

try xlog.open(logsDir: logsDir, cacheDir: cacheDir)
try xlog.info("NativeTag", "hello from Darwin")
try await xlog.flush()  // asynchronous — call it from an async context
try xlog.close()
```

The shared Swift `xlog` instance mirrors the Dart top-level getter. `flush()`
and `decode()` are async; their synchronous counterparts are `flushSync()` and
`decodeSync()`. Loading, symbol resolution, and decoding failures are thrown as
`XlogError`.

Coordinate the native and Dart sides so only one owner opens and closes the
shared appender. Do not close an appender that was never opened.

## Release symbol retention

Dart `record_use` cannot see JNA or `dlsym` calls. Any consuming app that uses
the native APIs must currently disable Mars link-hook tree shaking in its root
`pubspec.yaml`, otherwise native-only symbols can be removed in release builds:

```yaml
hooks:
  user_defines:
    mars:
      tree_shake: false
```

Always validate native calls in a release build as well as a debug build.

## Example

A complete runnable app — logging from Dart and from native code, browsing
and decoding log files — is available in [`example/`](example/).

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).
