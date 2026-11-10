# native_toolchain_x

[![pub package](https://img.shields.io/pub/v/native_toolchain_x.svg)](https://pub.dev/packages/native_toolchain_x)

A library to invoke the native C compiler installed on the host machine — a
drop-in replacement for
[`native_toolchain_c`](https://pub.dev/packages/native_toolchain_c) that adds
the builders needed to fetch and compile third-party C/C++ sources inside
[native assets](https://dart.dev/tools/native-assets) build hooks.

## Status: Experimental

**NOTE**: This package is published as a development prerelease
(`1.0.0-dev.0`) to solicit feedback. The API surface is expected to change —
potentially in breaking ways — before the stable `1.0.0` release.

`native_toolchain_x` starts from `native_toolchain_c` `0.19.5`, and everything
that package exports is available here under the same names, so a build hook
can switch imports without other changes. On top of that it adds:

- **`CMakeBuilder`** — configure, build, and install an existing CMake project
  for the target OS, architecture, SDK version, and NDK API level of the
  current build.
- **`RepositoryBuilder`** — fetch third-party sources into the shared build
  directory, either as a release `.tar.gz` verified against a SHA-256 digest or
  as a Git checkout at a refspec.
- **`Tools`** — resolve external build tools (`cmake`, `make`, `jom`, `tar`,
  `git`, `perl`, `nasm`) through the same resolver machinery used for compilers,
  with `resolveOrNull` for callers that want to handle a missing tool
  themselves.
- An optional `encoding` on `runProcess`, so tool output is decoded correctly
  on hosts whose ANSI code page is not UTF-8.

## Features

- **`CBuilder`** — compile C/C++ sources into a static library, a dynamic
  library, or an executable, with defines, include directories, forced
  includes, frameworks, libraries, flags, optimization level, and
  debug/release variants.
- **`CLinker`** — a link hook that links code assets and tree-shakes the
  result down to the symbols Dart actually uses
  (`LinkerOptions.treeshake`), with fully manual linker control
  (`LinkerOptions.manual`) as an escape hatch.
- **`CLibrary`** — build in the build hook and link in the link hook from one
  declaration, so link-time work (such as LTO) stays correct.
- **Toolchain discovery** — MSVC (located through `vswhere`), `clang`, `gcc`,
  Apple Clang, Xcode, the Android NDK, and WSL, including cross-compilation
  to Android and Linux from macOS and Windows hosts.
- **Native assets integration** — builders consume a `BuildInput` and write
  through a `BuildOutputBuilder`, so they drop straight into `hook/build.dart`
  and `hook/link.dart`.

## Getting started

- Dart SDK `^3.10.0` with native assets enabled (the default in recent SDKs).
- A C/C++ toolchain for each target platform:
  - Android: the Android NDK.
  - iOS / macOS: Xcode.
  - Windows: Visual Studio with the "Desktop development with C++" workload.
  - Linux: `gcc` or `clang` and GNU `make`.
- The external tools used by the builders, on `PATH`.

The builders need the following tools available:

| Tool | Required by |
| --- | --- |
| `cmake` | `CMakeBuilder` |
| `tar` | `RepositoryBuilder.tgz` |
| `git` | `RepositoryBuilder.git` |
| `make`, `nasm`, `perl` | Third-party CMake projects that need them |
| `jom` | Parallel `nmake`-style builds of OpenSSL on Windows (the `mars` hook) |

## Usage

Compile sources directly from a build hook:

```dart
// hook/build.dart
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final builder = CBuilder.library(
      name: 'my_lib',
      assetName: 'src/my_lib_bindings_generated.dart',
      sources: ['src/my_lib.c'],
      includes: ['src'],
    );
    await builder.run(input: input, output: output);
  });
}
```

Build a third-party CMake project — fetch and verify the archive, then
configure, build, and install it into the output directory:

```dart
// hook/build.dart
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';

const _url =
    'https://github.com/meta/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz';
const _sha256 = 'eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    await RepositoryBuilder.tgz(url: _url, sha256: _sha256)
        .run(input: input, output: output);

    await CMakeBuilder(
      srcDir: input.outputDirectoryShared.resolve('zstd-1.5.7/'),
      subDir: 'build/cmake/',
      variables: const {'ZSTD_BUILD_PROGRAMS': 'OFF'},
    ).run(input: input, output: output);
  });
}
```

`CMakeBuilder` installs into `<output>/out/` (configurable through `dstDir`
and `outDir`); the hook then registers the installed library as a code asset
with `output.assets.code.add(...)`, keyed by the binding's asset ID. A library
built this way is usually tree-shaken and linked from a link hook — see the
`zstd` package for that half of the setup.

## Example

The `zstd` package in this repository is the reference example: see
[`hook/build.dart`](https://github.com/invictus-dart/packages/blob/master/src/zstd/hook/build.dart)
for download + CMake + code asset registration, and
[`hook/link.dart`](https://github.com/invictus-dart/packages/blob/master/src/zstd/hook/link.dart)
for static linking with tree-shaking.

## Supported platforms

| Target | Host toolchain |
| --- | --- |
| Android | Android NDK (from macOS, Linux, or Windows hosts) |
| iOS | Xcode |
| macOS | Xcode / Apple Clang |
| Linux | `gcc` / `clang` |
| Windows | MSVC |

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).
