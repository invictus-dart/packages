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
  (`cmake`, `make`, `tar`, `git`, `perl`, `nasm`) through the same tool
  resolver machinery as the compilers.
- Added `HookInputUserDefinesExt.getValue` for reading typed `user_defines`.
- Added an optional `encoding` to `runProcess` and pinned MSVC output to UTF-8,
  so compiler diagnostics are decoded correctly on non-UTF-8 code pages.
- Note: this is a prerelease — the API surface may change in breaking ways
  before 1.0.0.
