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
| NASM | Windows | OpenSSL's x86/x86_64 assembly routines; install it if Configure reports NASM missing |
| Jom | Windows | builds and installs OpenSSL in parallel (`/J <cores>`); the build fails if it is not on `PATH` |
| Make | Linux, macOS, Android targets | builds and installs OpenSSL (`-j<cores>`) |
| Tar | all | `tar` extracts both release archives |
| CMake | all | `cmake` builds zstd |

The tools must be on `PATH`. On Windows the MSVC environment is resolved
through `vswhere`, so no Developer Command Prompt is required.

### Why `jom` and not `nmake`

Visual Studio's `nmake` has no parallel mode — `/J` and `-j` are absent from its
option list — so it compiles OpenSSL's ~1,100 translation units one after
another, which is what makes the Windows build take an order of magnitude
longer than the macOS/Linux ones for identical sources. `jom`
(<https://download.qt.io/official_releases/jom/jom.zip>, also bundled with Qt
Creator) is an nmake-compatible make that adds `/J <n>`, and passes the job
count down to the recursive `$(MAKE)` calls OpenSSL's makefile issues.

While compiling with `jom`, the hook exports `CL=/FS` to the build process:
OpenSSL's generated makefile passes `/Zi /Fdossl_static.pdb` to every `cl`
invocation without `/FS`, and concurrent compiles would otherwise abort with
`C1041: cannot open program database`. `/FS` routes PDB writes through
`mspdbsrv` without patching the makefile or the vendored sources.

OpenSSL is built with `jom /J <cores> build_libs` and then installed with
`jom /J 1 install`. The install rules are not independent: `install_dev` and
`install_runtime` both pull in `build_programs`/`build_libs`, whose recipes run
the makefile's `depend` target, and `depend` rewrites `makefile` by renaming
`makefile-<pid>` over it (`util/add-depends.pl`). Two concurrent instances
therefore fail with `Permission denied` while the other one holds the makefile
open, so the install is the one step that must stay serial.

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
