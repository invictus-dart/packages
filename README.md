# Packages

A collection of Dart and Flutter packages maintained by the Invictus Dart
team, spanning FFI bindings, [native assets](https://dart.dev/tools/native-assets)
build tooling, and the Flutter packages built on top of them. Native code is
compiled from source through build hooks, so no manual build step is needed
downstream.

## Overview

| Package | Description | Version |
| --- | --- | --- |
| [clover](src/clover/) | A lightweight MVVM framework for Flutter. It provides a ViewModel base class and a ViewModelBinding widget that rebuild views when the view model notifies changes. | [![pub package](https://img.shields.io/pub/v/clover.svg)](https://pub.dev/packages/clover) |
| [mars](src/mars/) | Tencent/mars for Dart, the cross-platform component library developed by WeChat, built from vendored source via native assets build hooks. | [![pub package](https://img.shields.io/pub/v/mars.svg)](https://pub.dev/packages/mars) |
| [mars_flutter](src/mars_flutter/) | Tencent/mars for Flutter. The Dart API is re-exported from mars, and the native APIs share the same library. | [![pub package](https://img.shields.io/pub/v/mars_flutter.svg)](https://pub.dev/packages/mars_flutter) |
| [mars_logging](src/mars_logging/) | An integration which records logs from the logging package into mars. | [![pub package](https://img.shields.io/pub/v/mars_logging.svg)](https://pub.dev/packages/mars_logging) |
| [native_toolchain_x](src/native_toolchain_x/) | A library to invoke the native C compiler installed on the host machine, with CMake and repository builders for building third-party sources in native assets hooks. | [![pub package](https://img.shields.io/pub/v/native_toolchain_x.svg)](https://pub.dev/packages/native_toolchain_x) |
| [zstd](src/zstd/) | Zstandard (zstd) bindings for Dart: fast lossless compression, compiled from the official release sources through native assets build hooks. | [![pub package](https://img.shields.io/pub/v/zstd.svg)](https://pub.dev/packages/zstd) |

## Status

`clover` follows its stable version line on pub.dev. All other packages are
published as development prereleases (`1.0.0-dev.N`) to solicit feedback;
their API surfaces are expected to change — potentially in breaking ways —
before their stable `1.0.0` releases.

## Requirements

- Dart SDK `^3.10.0` with native assets enabled (the default in recent SDKs).
- Flutter SDK for the Flutter-based packages (`clover`, `mars_flutter`) — see
  each package's SDK constraint.
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

Flutter-based packages (`clover`, `mars_flutter`) use the Flutter tool:
`flutter analyze` and `flutter test` from the package directory.

Build options for the hooks (source archives, checksums, tree-shaking) are set
through `hooks.user_defines` in the root `pubspec.yaml`.

Before publishing a package, validate it from its directory:

```sh
cd src/native_toolchain_x && dart pub publish --dry-run
```

Packages `zstd` and `mars` depend on `native_toolchain_x`, while
`mars_logging` and `mars_flutter` depend on `mars`, so publish in dependency
order: `native_toolchain_x` → `zstd` / `mars` → `mars_logging` / `mars_flutter`.
`clover` is standalone and can be published at any time.

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).

## License

MIT — see the [LICENSE](LICENSE) file and the `LICENSE` file of each package.
