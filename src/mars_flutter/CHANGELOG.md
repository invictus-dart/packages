## 1.0.0-dev.1

- Fixed Android release builds failing in `minifyReleaseWithR8`: JNA references
  `java.awt.*` classes (through `com.sun.jna.Native$AWT`) that do not exist on
  Android. The plugin's consumer ProGuard rules now carry `-dontwarn` rules for
  the four reported `java.awt` classes, so every app consuming the plugin
  inherits them automatically without touching its own `proguard-rules.pro`.
- Requires `mars` `^1.0.0-dev.2`, which fixes the Android runtime
  `UnsatisfiedLinkError` (missing `enter_once_region` / `commit_once_region`)
  and the armeabi-v7a `libc++_shared.so` bundling failure.

## 1.0.0-dev.0

- Initial development prerelease of the Mars Flutter plugin.
- The Dart API is re-exported from `package:mars`: the shared `xlog` instance
  and all XLog operations are available directly from `package:mars_flutter`,
  and Dart and native code log through the same appender instance.
- Adds `XlogView`, a widget that decodes a `.xlog` file (optionally with the
  ECDH private key for encrypted segments) and renders the plaintext lines.
- Native Android API (shared top-level `xlog` instance of
  `dev.invictus_dart.mars_flutter.Xlog`): binds the stable C ABI
  (`mars/src/mars.h`) with JNA — no Tencent Java/JNI wrapper required.
  Suspending `flush`/`decode` run on `Dispatchers.IO`; `flushSync`/`decodeSync`
  block the calling thread.
- Native iOS/macOS API (shared `xlog` instance): loads Flutter's bundled
  `mars.framework` with `dlopen`/`dlsym`; loading, symbol resolution, and
  decoding failures are thrown as `XlogError`. `flush`/`decode` are
  asynchronous; `flushSync`/`decodeSync` block the calling thread.
- Windows and Linux register the plugin through the standard plugin
  registrants; use the Dart API (`package:mars`) for logging on those
  platforms.
- Note: this is a prerelease — the API surface may change in breaking ways
  before 1.0.0.
