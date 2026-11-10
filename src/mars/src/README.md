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

## Third-party libraries (OpenSSL, zstd)

Upstream mars vendors its third-party dependencies inside the tree: OpenSSL
1.1.1l headers under `openssl/include/` and zstd 1.4.4 sources under
`zstd/lib/`. Per project rules both are upgraded here — OpenSSL to 3.5.9
(latest LTS) and zstd to 1.5.7 (latest release) — and neither is vendored
anymore: the static libraries are built from the official release tarballs
by `hook/openssl.dart` and `hook/zstd.dart`, whose install steps put the
headers next to the libraries in the hook output directory
(`openssl/out/include/`, `zstd/out/include/`).

`hook/build.dart` passes both `out/include` directories to the compilers as
include directories, so the headers always come from the same build as the
static libraries linked from the same output for the current target
platform: there is no cross-platform header set to maintain, and upgrades
need no manual header sync.

The include statements that referenced the removed copies were switched to
angle brackets — the convention for headers resolved from the external
include path — and placed in sorted position within their include blocks
(each site carries a `[invictus-dart local fix ...]` comment; see the table
below). Headers that stay in-tree (zlib, micro-ecc) keep quoted includes.

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
| `comm/shuffle.h` | OpenSSL include `mars/openssl/include/openssl/rand.h` → `<openssl/rand.h>` (see "Third-party libraries") |
| `comm/strutil.cc` | OpenSSL include `openssl/md5.h` → `<openssl/md5.h>` (see "Third-party libraries") |
| `comm/thread/spinlock.h` | `_M_ARM64` `cpu_relax()` uses `__yield()` (x86-only `_mm_pause` / macro `YieldProcessor` fail to link) |
| `comm/verinfo.h` | `MARS_BUILD_TIME` / `MARS_BUILD_TIMESTAMP` snapshot defines commented out; the build hook (`hook/build.dart`, xlog1 `CBuilder`) injects them as `-D` defines so every .xlog header records the actual compilation time |
| `comm/windows/thread/thread.h` | OpenSSL include `mars/openssl/include/openssl/crypto.h` → `<openssl/crypto.h>` (see "Third-party libraries") |
| `comm/xlogger/preprocessor.h` | `PP_SIZE` uses the standard implementation under the conforming MSVC preprocessor |
| `stn/src/special_ini.h` | OpenSSL include `mars/openssl/include/openssl/md5.h` → `<openssl/md5.h>` (see "Third-party libraries") |
| `xlog/crypt/decode_log_file_c_impl/decode_log_file.c` | zstd include `zstd/lib/zstd.h` → `<zstd.h>` (see "Third-party libraries") |
| `xlog/src/log_zstd_buffer.h` | zstd include `zstd/lib/zstd.h` → `<zstd.h>` (see "Third-party libraries") |

Rows are sorted by path; every include-path row is a consequence of the
third-party header strategy described above, not an independent fix.

## Intentional differences from upstream

- Build system: upstream uses CMake + Python scripts; this repository uses
  Dart hooks (`hook/build.dart` / `hook/link.dart`, native_toolchain_x).
- Artifacts: upstream Android builds two JNI libraries (marsstn.so /
  marsxlog.so); this repository builds a single `libmars.so` for Dart FFI,
  with the JNI sources compiled separately into `libjni.a`.
- Third-party dependencies: OpenSSL 3.5.9 and zstd 1.5.7, built by the Dart
  hooks and not vendored (see "Third-party libraries" above).
- Source differences are tracked via `git diff` against the upstream branch;
  the module source lists match upstream (445 compilation units, excluding
  unittest/mock and JNI, which stay outside libmars).
