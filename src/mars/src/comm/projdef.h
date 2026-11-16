// Local addition, not part of the vendored tree (see hook/build.dart,
// _getForcedIncludes).
//
// Mirrors the structure of the upstream comm/projdef.h: this file is only a
// platform dispatcher, the real definitions live in the per-platform
// subdirectory (linux/projdef.h). Windows keeps using the vendored
// src/mars/comm/projdef.h, which dispatches to comm/windows/projdef.h.
#ifndef prjdef_h
#define prjdef_h

#ifdef __linux__
#include "linux/projdef.h"
#endif

#endif /* prjdef_h */
