# Packages

A collection of Dart packages maintained by the Invictus Dart team, focused on
FFI bindings and [native assets](https://dart.dev/tools/native-assets) build
tooling. Everything here compiles its native code from source through build
hooks, so no manual build step is needed downstream.

## Overview

| Package | Description | Version |
| --- | --- | --- |
| [mars](src/mars/) | Dart FFI bindings for [Mars](https://github.com/Tencent/mars), built from vendored source through native assets build hooks. | [![pub package](https://img.shields.io/pub/v/mars.svg)](https://pub.dev/packages/mars) |
| [mars_logging](src/mars_logging/) | Records logs from `package:logging` into Mars XLog. | [![pub package](https://img.shields.io/pub/v/mars_logging.svg)](https://pub.dev/packages/mars_logging) |
| [native_toolchain_x](src/native_toolchain_x/) | Invokes the native C compiler installed on the host machine, with CMake and repository builders for compiling third-party sources in build hooks. | [![pub package](https://img.shields.io/pub/v/native_toolchain_x.svg)](https://pub.dev/packages/native_toolchain_x) |
| [zstd](src/zstd/) | Bindings for [Zstandard](https://facebook.github.io/zstd/), compiled from the official release sources through native assets build hooks. | [![pub package](https://img.shields.io/pub/v/zstd.svg)](https://pub.dev/packages/zstd) |

## Status: Experimental

All packages are currently published as development prereleases
(`1.0.0-dev.N`) to solicit feedback. Their API surfaces are expected to change
— potentially in breaking ways — before the stable `1.0.0` releases.

## Requirements

- Dart SDK `^3.10.0` with native assets enabled (the default in recent SDKs).
- A C/C++ toolchain for each target platform:
  - Android: the Android NDK.
  - iOS / macOS: Xcode.
  - Windows: Visual Studio with the "Desktop development with C++" workload,
    plus Qt's `jom`.
  - Linux: `gcc`/`clang` and GNU `make`.
- The extra build tools each package needs — `cmake`, `tar`, `perl`, `nasm`
  and Qt's `jom` — are listed in the package READMEs, together with the
  platform-specific details.
- Windows builds require `jom` on `PATH`. Visual Studio's `nmake` is not a
  substitute: it has no parallel mode, and compiling OpenSSL serially under
  `nmake` takes an order of magnitude longer than under `jom` or `make -j`.

## Development

This repository is a single [Dart pub workspace](https://dart.dev/tools/pub/workspaces);
the root `pubspec.yaml` lists every package under `src/`, and dependencies
resolve together.

```sh
dart pub get                  # resolve the whole workspace once, from the root
dart analyze src/mars         # analyze a package from the root
cd src/zstd && dart test      # run a package's tests from its own directory
```

Build options for the hooks (source archives, checksums, tree-shaking) are set
through `hooks.user_defines` in the root `pubspec.yaml`.

Before publishing a package, validate it from its directory:

```sh
cd src/native_toolchain_x && dart pub publish --dry-run
```

Package `zstd` depends on `native_toolchain_x` and `mars_logging` depends on
`mars`, so publish in dependency order: `native_toolchain_x` → `zstd` / `mars`
→ `mars_logging`.

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).

## License

MIT — see the [LICENSE](LICENSE) file and the `LICENSE` file of each package.
