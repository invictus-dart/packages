# mars

[![pub package](https://img.shields.io/pub/v/mars.svg)](https://pub.dev/packages/mars)

[Tencent/mars](https://github.com/Tencent/mars) for Dart, the cross-platform
component library developed by WeChat (Tencent) — built natively from vendored
source through [native assets](https://dart.dev/tools/native-assets) build
hooks, no manual build steps required.

## Status: Experimental

**NOTE**: This package is published as a development prerelease
(`1.0.0-dev.3`) to solicit feedback. The API surface is expected to change —
potentially in breaking ways — before the stable `1.0.0` release.

Currently the following Mars module is exposed:

- **XLog** — Mars' high-performance logging component: compressed and
  optionally encrypted log files, cached writing with rotation, and offline
  decoding.

Other Mars modules (STN networking, SDT, Comm) are vendored and compiled into
the library, but not yet bridged to Dart.

## Features

- **XLog logging** with level filtering (`verbose` … `fatal`), tags, and
  automatic file/line/caller capture from Dart stack traces.
- **Buffered writing** — async appender (flushed periodically) or sync
  appender (written on every call), with blocking `flushSync` / `decodeSync`
  and isolate-based `flush` / `decode`.
- **Log compression** — zlib or zstd, configurable level 1–9.
- **Log encryption** — ECDH public-key encryption of log files.
- **Rotation** — by file size and by alive duration.
- **Offline decoding** — decode `.xlog` files back to plaintext, with optional
  ECDH private key for encrypted segments.

## Getting started

- Dart SDK `^3.10.0` with native assets enabled (the default in recent SDKs).
- A working C/C++ toolchain for each target platform:
  - Android: the Android NDK.
  - iOS / macOS: Xcode.
  - Windows: Visual Studio with the C++ workload.
  - Linux: the system compiler (`gcc`/`clang`) and `make`.

The build hooks download a prebuilt OpenSSL install tree and the zstd release
tarball, compile zstd and the vendored Mars sources, then link everything into
a single dynamic library (`libmars.so` / `libmars.dylib` / `mars.dll`) for each
target. Nothing needs to be configured.

### Third-party libraries

OpenSSL is consumed as a prebuilt install tree — headers plus the static
`libcrypto`/`libssl` — published in the `invictus-dart/openssl` repository, one
archive per target (`android-arm64`, `darwin64-arm64`, `VC-WIN64A`, and so on).
Every archive is pinned by URL and SHA-256 in
`lib/src/hook/openssl.download.dart`: no Perl, NASM or `jom` is involved, and the
headers always belong to the same build as the libraries. zstd is still compiled
from the official release tarball with CMake.

Downloads can be routed through a mirror with the `openssl` user define. The
value replaces the defaults wholesale, so it must carry every entry the build
uses, for example:

```yaml
hooks:
  user_defines:
    mars:
      openssl:
        android:
          arm64:
            url: https://gh-proxy.org/https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-android-arm64.tar.gz
            sha256: f07d46e5fbbb677922329e5ec2ad08eb7cc7271c886835b0acf3225e7fb6fdda
```

Tools required on `PATH`:

| Tool | Purpose |
| --- | --- |
| `tar` | extracts the OpenSSL and zstd archives |
| `cmake` | configures, builds and installs zstd |

## Usage

Open the logger at startup, log through the shared [xlog] instance, flush or
close before exit, and decode log files offline:

```dart
import 'dart:io';

import 'package:mars/mars.dart';

void main() async {
  xlog.open(
    mode: AppenderMode.async,     // buffered, recommended
    level: LogLevel.debug,        // global level filter
    logsDir: '/path/to/logs',
    cacheDir: '/path/to/cache',
    namePrefix: 'log',
    compressMode: CompressMode.zstd,
    // pubKey: '<64 hex chars>',  // ECDH public key to encrypt logs
    useConsole: true,
  );

  xlog.info('MyTag', 'hello');
  xlog.error('MyTag', 'something failed', error, stackTrace);

  await xlog.flush(); // wait until buffered logs are on disk
  xlog.close();       // merge cached logs into final files

  final input = await file.readAsBytes();
  final output = await xlog.decode(input); // add privKey: for encrypted segments
  final text = utf8.decode(output);
}
```

A complete runnable example is available in [`example/mars_example.dart`](example/mars_example.dart).

## Supported platforms

| Platform | Artifact |
| --- | --- |
| Android | `libmars.so` (arm64-v8a, armeabi-v7a, x86_64) |
| iOS | `libmars.dylib` |
| macOS | `libmars.dylib` |
| Windows | `mars.dll` |
| Linux | `libmars.so` |

## Build system

All platforms build through the Dart hooks (`hook/build.dart` compiles,
`hook/link.dart` trims): each Mars module (`app`, `baseevent`, `boot`, `comm`,
`sdt`, `stn`, `xlog`) plus the third-party dependencies (boost, zstd) is
compiled as a static library, then linked with OpenSSL and the platform system
libraries into a single dynamic library. The vendored source tree and its
provenance (upstream repository, branch, commit, local fixes) are documented in
[`src/README.md`](src/README.md).

Dart consumes the library exclusively through `dart:ffi`: the FFI bridge
(`src/mars.cpp` → `src/mars.h`) is the only entry point, and the bindings in
`lib/src/mars_bindings_generated.dart` are generated by `ffigen` (`tool/ffigen.dart`).

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).
