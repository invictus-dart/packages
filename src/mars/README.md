# mars

[![pub package](https://img.shields.io/pub/v/mars.svg)](https://pub.dev/packages/mars)

Dart bindings for [Mars](https://github.com/Tencent/mars), the cross-platform
component library developed by WeChat (Tencent) — built natively from vendored
source through [native assets](https://dart.dev/tools/native-assets) build
hooks, no manual build steps required.

## Status: Experimental

**NOTE**: This package is published as a development prerelease
(`1.0.0-dev.0`) to solicit feedback. The API surface is expected to change —
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

The build hooks download and compile OpenSSL (latest LTS) and zstd from
official release tarballs, then compile the vendored Mars sources and link
everything into a single dynamic library (`libmars.so` / `libmars.dylib` /
`mars.dll`) for each target. Nothing needs to be configured.

### Building OpenSSL

OpenSSL is built from source first, so its build environment has to be
available on top of the C/C++ toolchain above:

| Tool | Platform | Purpose |
| --- | --- | --- |
| Perl | all | runs `perl Configure` (Strawberry Perl on Windows, the system Perl elsewhere) |
| `make` | Linux, macOS, Android targets | builds and installs OpenSSL (`nmake` is used only when targeting Windows) |
| `nmake` | Windows | builds and installs OpenSSL; it ships with the Visual Studio C++ workload and is taken from the detected MSVC toolset |
| NASM | Windows | OpenSSL's x86/x86_64 assembly routines; install it if Configure reports NASM missing |
| `cmake`, `tar` | all | `cmake` builds zstd, `tar` extracts both release archives |

The tools must be on `PATH`. On Windows the MSVC environment is resolved
through `vswhere`, and `nmake` is invoked from the same toolset directory as
the compiler, so no Developer Command Prompt is required.

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
    cacheDir: '/path/to/logs/cache',
    namePrefix: 'log',
    compressMode: CompressMode.zstd,
    // pubKey: '<64 hex chars>',  // ECDH public key to encrypt logs
    useConsole: true,
  );

  xlog.info('MyTag', 'hello');
  xlog.error('MyTag', 'something failed', error, stackTrace);

  await xlog.flush(); // wait until buffered logs are on disk
  xlog.close();       // merge cached logs into final files

  final bytes = await File('/path/to/log_20260101.xlog').readAsBytes();
  final plaintext = await xlog.decode(bytes);
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
