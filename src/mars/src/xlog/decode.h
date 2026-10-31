// Tencent is pleased to support the open source community by making Mars available.
// Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.

// Licensed under the MIT License (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://opensource.org/licenses/MIT

// Unless required by applicable law or agreed to in writing, software distributed under the License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions and
// limitations under the License.

// xlog log-file decoding API (adapted from
// mars/xlog/crypt/decode_log_file_c_impl/decode_log_file.c, exposed for FFI use).
// Keep this file ASCII-only: the build does not pass /utf-8 to MSVC.

#ifndef XLOG_DECODE_H
#define XLOG_DECODE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Decode an xlog log-file image to plaintext (all magic variants:
 * crypt / compress / ECDH+TEA).
 *
 * Args:
 *   buffer        - raw log file bytes (read-only)
 *   bufferSize    - length of buffer in bytes
 *   outBuffer     - [in/out] decoded plaintext. The incoming value is
 *                   reused via realloc() and must be NULL or a pointer
 *                   returned by a previous decode() call from the same C
 *                   runtime. On success it holds the output (malloc'd,
 *                   caller-owned)
 *   outBufferSize - [out] output length in bytes; NOT NUL-terminated
 *   privKey       - server ECDH private key (64 hex chars). NULL = no key:
 *                   an ECDH-encrypted segment is then skipped with a "Get
 *                   ECDH key error" placeholder and decoding continues
 *                   with the unencrypted parts. A non-NULL malformed key
 *                   (empty string, bad hex, wrong length) fails with -7
 *
 * Returns (negated upstream CLI exit codes):
 *    0  success
 *   -1  no valid log header found (not a failure)
 *   -2  memory allocation failure
 *   -5  output buffer realloc failure
 *   -6  zlib/zstd decompression failure
 *   -7  privKey is not NULL but malformed
 *
 * On any error decoding stops at the first failure and diagnostics go to
 * stderr. *outBuffer stays valid on every path: -1 (and a -2 raised by
 * the initial allocation) keeps the incoming value, while the other
 * errors replace it with the partially decoded output. The implementation
 * keeps no mutable global state and never calls exit(), so concurrent
 * decode() calls on separate buffers are safe.
 */
int decode(const char* buffer, size_t bufferSize, char** outBuffer, size_t* outBufferSize, const char* privKey);

#ifdef __cplusplus
}
#endif

#endif  // XLOG_DECODE_H
