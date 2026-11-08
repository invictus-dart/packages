
#ifndef Mars_verinfo_h
#define Mars_verinfo_h

#define MARS_REVISION "a8c6c7d3"
#define MARS_PATH "release/2024-t3.1"
#define MARS_URL ""
// [invictus-dart local fix -- do not sync back to upstream Tencent/mars]
// MARS_BUILD_TIME / MARS_BUILD_TIMESTAMP are injected by the build hook
// (hook/build.dart, xlog1 CBuilder) as -D defines so that they reflect the
// actual compilation time. They must expand to a string literal / integer
// because xlog/src/appender.cc concatenates them into the .xlog header;
// compiling without the defines is a deliberate loud failure.
// #define MARS_BUILD_TIME "2026-10-26 17:33:18"
#define MARS_TAG ""
// #define MARS_BUILD_TIMESTAMP 1793007198

#endif
