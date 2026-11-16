// Force-included into every Mars translation unit when the target OS is Linux
// (see hook/build.dart, _getForcedIncludes).
//
// Why: several vendored headers declare fixed-width integer types without
// including <stdint.h> themselves, e.g. comm/strutil.h (uint8_t / uint64_t),
// comm/network/getifaddrs.h (uint8_t / uint32_t) and comm/http.h (uint64_t).
// Apple's libc++ and Android's bionic pull those typedefs in transitively
// through <string>/<sstream>, so the upstream tree compiles there; libstdc++
// on Linux does not, and the headers fail with "unknown type name 'uintX_t'"
// (observed with clang compiling comm/http.cc and comm/network/getifaddrs.cc).
//
// Windows builds are already covered by the upstream forced include
// (comm/projdef.h, which includes <stdint.h> itself). Rather than editing a
// dozen vendored headers, Linux gets the equivalent forced include here. This
// file lives outside src/mars/ and is not part of the vendored tree.
#ifndef MARS_LINUX_STDINT_H_
#define MARS_LINUX_STDINT_H_

#include <stdint.h>

#endif  // MARS_LINUX_STDINT_H_
