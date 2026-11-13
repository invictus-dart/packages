# mars_flutter

Flutter plugin for Tencent/Mars. The Dart API is re-exported from `mars`, and
the native Android and iOS/macOS APIs expose the same Xlog operations through
the stable C ABI in `mars/src/mars.h`.

- Android binds the C ABI with JNA; no Tencent Java/JNI wrapper is required.
- iOS/macOS load Flutter's bundled `mars.framework` with `dlopen`/`dlsym`.
- Dart and native code share the same Mars library and xlog appender instance.

## Android

```kotlin
import dev.invictus_dart.mars_flutter.Xlog

Xlog.open(logsDir = logsDir, cacheDir = cacheDir)
Xlog.info("NativeTag", "hello from Android")
Xlog.flushSync()
Xlog.close()
```

`flush()` and `decode()` are suspending functions and run their blocking work
on `Dispatchers.IO`; `flushSync()` and `decodeSync()` block the calling thread.

## iOS/macOS

```swift
try xlog.open(logsDir: logsDir, cacheDir: cacheDir)
try xlog.info("NativeTag", "hello from Darwin")
try xlog.flushSync()
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
