# Vendored Tencent/Mars source

This directory contains Tencent/Mars source code vendored into the `mars`
Dart package for building with `native_toolchain_c`.

## Provenance

- Upstream repository: https://github.com/Tencent/mars
- Branch: `release/2024-t3.1` (latest release branch)
- Commit: `a8c6c7d3` (`git describe`: `v1.3.0-1261-ga8c6c7d3`)
- Copied on: 2026-10-25

## Layout

| Directory   | Contents                                             | Notes                          |
|-------------|------------------------------------------------------|--------------------------------|
| `comm/`     | Mars common library (xlogger, socket, network, ...)  | Windows subdirs included       |
| `boot/`     | Boot module                                          |                                |
| `boost/`    | Trimmed Boost (headers + libs sources)               | `mars-boost` static lib        |
| `app/`      | App module                                           |                                |
| `baseevent/`| BaseEvent module                                     |                                |
| `xlog/`     | XLog logging module (src + crypt)                    |                                |
| `sdt/`      | SDT (network diagnosis) module                       |                                |
| `stn/`      | STN (network) module                                 | Requires OpenSSL               |
| `rapidjson/`| RapidJSON headers (header-only)                      |                                |
| `openssl/`  | OpenSSL headers + prebuilt static libs (Windows)     | `include/`, `openssl_lib_windows/{x86,x64}/` |
| `zstd/`     | Zstandard `lib/` sources (v1.4.4)                    | Compiled statically            |

## Source selection (mirrors official CMake, Windows/MSVC branch)

- Per-module `.cc` / `.c` / `.cpp` globs follow each module's `CMakeLists.txt`
  MSVC branch (`comm/CMakeLists.txt`, `xlog/CMakeLists.txt`, ...).
- Excluded from compilation: `*_unittest.cc`, `*_mock.cc`, `jni/`, `android/`,
  `objc/`, `ohos/`, `unix/` (non-Windows), `uwpproj/`, `wp8/`,
  `comm/network/local_routetable.*`, `comm/socket/getsocktcpinfo.*`.
- Boost compiles only the sources listed in `boost/CMakeLists.txt`
  (plus the win32 thread sources).
- `comm/windows/projdef.h` is force-included into every translation unit
  (`/FI`), matching the official MSVC build.

## Official build reference

The upstream build scripts (`mars/mars/build_windows.py`, `mars/mars/CMakeLists.txt`)
are **not** copied; the equivalent settings are implemented in
`hook/build.dart` and `hook/link.dart` of this package.

- MSVC defines: `_WIN32 WIN32 _WIN64 WIN64 UNICODE _UNICODE NOMINMAX _LIB`
- Boost define: `BOOST_NO_EXCEPTIONS`
- Warning suppressions: `/wd4003 /wd4819 /wd4996 /wd4244 /wd4101 /wd4200 /wd4800 /wd4005 /wd4334`
- Static CRT: `/MT`
- Link: `libcrypto.lib libssl.lib` (prebuilt, `openssl_lib_windows/<arch>`)
  plus system libs (`ws2_32 iphlpapi winhttp wininet advapi32 crypt32 user32
  gdi32 shell32 ole32 runtimeobject`).

## License

Mars is MIT licensed (see `LICENSE` in the upstream repo). RapidJSON is MIT.
Zstandard is BSD-3-Clause (see `zstd/LICENSE`). OpenSSL prebuilt libs are
Apache-2.0/OpenSSL licensed.
