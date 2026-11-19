## 1.0.0-dev.3

- `RepositoryBuilder.tgz` is now `DownloadBuilder.tgz` (breaking change for
  callers): it downloads a release archive, verifies the SHA-256 digest and
  extracts it into the shared build directory. `RepositoryBuilder` keeps only
  `.git`. The archive is written as `<name>.tmp` and renamed to `<name>` after
  a successful extraction, so an archive present in the build directory is
  always a complete one and is reused instead of downloaded again.

## 1.0.0-dev.2

- Fixed Android 32-bit ARM (armeabi-v7a) builds: `CppSharedBuilder` derived the
  `libc++_shared.so` sysroot path from the clang target triple
  (`armv7a-linux-androideabi`), but the NDK sysroot library directories are
  named after the platform triples (`arm-linux-androideabi`); the copy failed
  with a `PathNotFoundException`. The builder now uses a dedicated
  platform-triple table that intentionally differs from the clang target flags.

## 1.0.0-dev.1

- `CBuilder` and `CLinker` no longer report files inside the hook output
  directory (`outputDirectoryShared`, and its checksum subdirectory
  `outputDirectory`) as dependencies. Builds that install third-party
  artifacts during the hook (for example the OpenSSL and zstd headers) no
  longer create a "modified during build" dependency, which used to invalidate
  the hook cache on every build
  (`File modified during build. Build must be rerun.`).

## 1.0.0-dev.0

- Initial development prerelease of `native_toolchain_x`.
- Based on `native_toolchain_c` `0.19.5`: `CBuilder`, `CLinker`, `CLibrary`,
  toolchain discovery, and the build/link hook integration are available under
  the same API, so existing build hooks can switch to this package by changing
  their imports.
- Added `CMakeBuilder`, which configures, builds, and installs a CMake project
  from the build hook for the target OS, architecture, SDK version, and NDK API
  level, with optional extra `-D` variables.
- Added `RepositoryBuilder.tgz` (downloads a release archive and verifies it
  against a SHA-256 digest before extracting) and `RepositoryBuilder.git`
  (checks out a given refspec); both default to the shared build directory, so
  sources are reused across builds.
- Added `Tools`, which resolves the external build tools used by the builders
  (`cmake`, `make`, `jom`, `tar`, `git`, `perl`, `nasm`) through the same tool
  resolver machinery as the compilers. `Tools.jom` lives on `PATH` and exposes
  the `jom`/`nmake`-style make needed for parallel builds on Windows.
- Added `ToolExt.resolveOrNull`, which returns `null` instead of throwing when a
  tool is missing, so callers can report a targeted error.
- Added `HookInputUserDefinesExt.getValue` for reading typed `user_defines`.
- Added an optional `encoding` to `runProcess` and pinned MSVC output to UTF-8,
  so compiler diagnostics are decoded correctly on non-UTF-8 code pages.
- Note: this is a prerelease — the API surface may change in breaking ways
  before 1.0.0.
