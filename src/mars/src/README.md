# Mars source (vendored) provenance

`src/mars/` is vendored source copied from the open-source repository
**Tencent/mars**. In principle it is never modified; changes are allowed only
for compile fixes that cannot be avoided, and each must be explained in a
code comment.

## Upstream repository

| Item | Value |
|---|---|
| Repository | git@github.com:Tencent/mars.git (https://github.com/Tencent/mars) |
| Remote branch | `release/2024-t3.1` (refs/heads/release/2024-t3.1) |
| Remote branch tip commit | `a8c6c7d37374fc435c69999b389732b377745106` (2024-09-05, `log(comm): add error log`) |
| Version | `comm/verinfo.h` → `MARS_REVISION "a8c6c7d3"` |

Notes:
- The vendored tree matches the remote tip `a8c6c7d3` file-for-file (0
  differences across boot/app/baseevent/sdt/stn/xlog/comm/boost and the
  root CMakeLists; `libraries/` also matches upstream).
- `comm/verinfo.h` is a build-time artifact of upstream
  `mars_utils.py gen_mars_revision_file`; the copy in this repository carries
  locally generated values (REVISION=a8c6c7d3, PATH=release/2024-t3.1,
  BUILD_TIME = local generation time). The verinfo.h checked into the upstream
  repository is a leftover from the previous release and gets overwritten at
  build time, so neither file counts as a source difference.
- OpenSSL is deliberately upgraded to 3.5.9 (upstream: 1.1.1l) per project
  rules.
- zstd is deliberately upgraded to 1.5.7 (upstream: 1.4.4) per project rules:
  the vendored zstd sources were removed and only the public headers are kept
  under `zstd/include/zstd/` (mirroring `openssl/include/openssl/`); the
  static library is built by `hook/zstd.dart` from the official release
  tarball. The two `#include "zstd/lib/zstd.h"` sites were adjusted to
  `#include "zstd.h"` (see the comments in those files).

## Modification comment format

All comments and documentation are written in English (project rule). Every
deliberate change inside the vendored tree MUST be marked as follows, so that
a future upstream sync can find and re-apply (or drop) each local fix:

1. **Vendored-file changes** — a comment block immediately above the change,
   starting with the exact marker:

   ```c
   // [invictus-dart local fix -- do not sync back to upstream Tencent/mars]
   // <what breaks without the fix (compiler error / behavior)>
   // <what the fix does, and which upstream project (e.g. boostorg/predef)
   //  the fix matches, if applicable>
   ```

   Keep the marker line byte-identical everywhere; it is the search key
   (`grep -rn "invictus-dart local fix" src/mars/`) for auditing local
   changes.

2. **Adapted copies outside the vendored tree** (e.g. `src/xlog/decode.c`,
   the library-style adaptation of `xlog/crypt/decode_log_file_c_impl/
   decode_log_file.c`) — state the provenance and divergence policy once in
   the file header, then mark every change with a `// Fix:` comment
   (review by searching the file for `Fix:`).

3. **Regenerated build artifacts** (e.g. `comm/verinfo.h`) are not counted as
   modifications for their generated values (they carry locally generated
   values by design); the one deliberate edit inside `comm/verinfo.h`
   (timestamp defines commented out, values injected by the build hook) is
   listed in the table below.

### Current local fixes (vs upstream `a8c6c7d3`)

| File | Reason |
|---|---|
| `boost/iostreams/detail/config/fpos.hpp` | MSVC STL ≥ 14.1 removed `fpos::seekpos` / `_FPOSOFF`; matches boostorg/iostreams |
| `boost/libs/thread/src/win32/tss_pe.cpp` | `_M_ARM64` missing from the `/alternatename` branch; matches boostorg/thread |
| `boost/predef/architecture/arm.h` | `_M_ARM64` not detected; matches boostorg/predef |
| `boost/preprocessor/config/config.hpp` | take the STRICT path under `/Zc:preprocessor` (`_MSVC_TRADITIONAL == 0`) |
| `comm/thread/spinlock.h` | `_M_ARM64` `cpu_relax()` uses `__yield()` (x86-only `_mm_pause` / macro `YieldProcessor` fail to link) |
| `comm/xlogger/preprocessor.h` | `PP_SIZE` uses the standard implementation under the conforming MSVC preprocessor |
| `xlog/crypt/decode_log_file_c_impl/decode_log_file.c` | zstd header path (`zstd/lib/zstd.h` → `zstd.h`) |
| `xlog/src/log_zstd_buffer.cc`, `log_zstd_buffer.h` | `Flush()` now emits the zstd frame epilogue; zstd header path |
| `comm/verinfo.h` | `MARS_BUILD_TIME` / `MARS_BUILD_TIMESTAMP` snapshot defines commented out; the build hook (`hook/build.dart`, xlog1 `CBuilder`) injects them as `-D` defines so every .xlog header records the actual compilation time |

Header-only upgrades (whole-directory, not per-file fixes):
`openssl/include/openssl/` → 3.5.9, `zstd/include/` → 1.5.7 (see above).

## Intentional differences from upstream

- Build system: upstream uses CMake + Python scripts; this repository uses
  Dart hooks (`hook/build.dart` / `hook/link.dart`, native_toolchain_c).
- Artifacts: upstream Android builds two JNI libraries (marsstn.so /
  marsxlog.so); this repository builds a single `libmars.so` for Dart FFI,
  with the JNI sources compiled separately into `libjni.a`.
- OpenSSL: upstream 1.1.1l; this repository 3.5.9 (latest LTS, per project
  rules).
- zstd: upstream 1.4.4; this repository 1.5.7 (latest release, per project
  rules) — sources replaced by headers-only under `zstd/include/zstd/`, the
  static library is built by `hook/zstd.dart` from the official tarball.
- Source differences are tracked via `git diff` against the upstream branch;
  the module source lists match upstream (445 compilation units, excluding
  unittest/mock and JNI, which stay outside libmars).
