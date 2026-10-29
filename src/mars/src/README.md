# mars 源码（vendored）来源记录

本目录 `src/mars/` 为从腾讯开源仓库 **Tencent/mars** 拷贝的 vendored 源码，原则上不做任何更改；仅当遇到必须修复的编译问题时才允许修改，且须在代码注释中说明原因。

## 上游仓库信息

| 项 | 值 |
|---|---|
| 仓库 | git@github.com:Tencent/mars.git（https://github.com/Tencent/mars） |
| 远程分支 | `release/2024-t3.1`（refs/heads/release/2024-t3.1） |
| 远程分支 tip commit | `a8c6c7d37374fc435c69999b389732b377745106`（2024-09-05，`log(comm)：添加错误日志`） |
| 对应版本号 | `comm/verinfo.h` → `MARS_REVISION "a8c6c7d3"` |

说明：
- vendored 源码树与远程 tip `a8c6c7d3` 逐文件一致（boot/app/baseevent/sdt/stn/xlog/comm/boost/zstd/根 CMakeLists 均 0 差异；`libraries/` 亦与上游一致）。
- `comm/verinfo.h` 为上游 `mars_utils.py gen_mars_revision_file` 的构建期生成物，仓库内为本地生成值（REVISION=a8c6c7d3、PATH=release/2024-t3.1、BUILD_TIME 为本地生成时间）；上游仓库内检入的 verinfo.h 是上一 release 残留，构建时会被重写，二者不作为源码差异依据。
- OpenSSL 按项目规则升级为 3.5.9（上游为 1.1.1l），属有意差异。

## 本仓库与上游的差异（有意为之）

- 编译体系：上游 CMake + Python 脚本；本仓库为 Dart hooks（`hook/build.dart` / `hook/link.dart`，native_toolchain_c）。
- 产物：上游 Android 产出 marsstn.so / marsxlog.so 两个 JNI 库；本仓库产出单一 `libmars.so`（Dart FFI），JNI 源码独立编译为 `libjni.a`。
- OpenSSL：上游 1.1.1l；本仓库 3.5.9（最新 LTS，项目规则）。
- 源码差异以 `git diff` 与上游分支比对为准；模块源码列表与上游一致（445 编译单元，排除 unittest/mock 与 JNI 于 libmars 之外）。
