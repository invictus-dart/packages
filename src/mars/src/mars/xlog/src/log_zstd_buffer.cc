// Tencent is pleased to support the open source community by making Mars available.
// Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.

// Licensed under the MIT License (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://opensource.org/licenses/MIT

// Unless required by applicable law or agreed to in writing, software distributed under the License is
// distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions and
// limitations under the License.

/*
 * log_zstd_buffer.cpp
 *
 *  Created on: 2020-3-5
 *      Author: yanguoyue
 */

#include "log_zstd_buffer.h"

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#include <algorithm>
#include <cstdio>
#include <string>

#include "xlog/crypt/log_crypt.h"
#include "xlog/crypt/log_magic_num.h"

#ifdef WIN32
#define snprintf _snprintf
#endif

namespace mars {
namespace xlog {

LogZstdBuffer::LogZstdBuffer(void* _pbuffer, size_t _len, bool _isCompress, const char* _pubkey, int level)
: LogBaseBuffer(_pbuffer, _len, _isCompress, _pubkey) {
    if (is_compress_) {
        cctx_ = ZSTD_createCCtx();
        ZSTD_CCtx_setParameter(cctx_, ZSTD_c_compressionLevel, level);
        ZSTD_CCtx_setParameter(cctx_, ZSTD_c_windowLog, 16);
    }
}

LogZstdBuffer::~LogZstdBuffer() {
    if (is_compress_ && cctx_ != nullptr) {
        ZSTD_inBuffer input = {nullptr, 0, 0};
        ZSTD_outBuffer output = {nullptr, 0, 0};
        ZSTD_compressStream2(cctx_, &output, &input, ZSTD_e_end);
        ZSTD_freeCCtx(cctx_);
    }
}

// [invictus-dart local fix -- do not sync back to upstream Tencent/mars]
// Upstream Flush() feeds ZSTD_e_end a zero-capacity output buffer and drops
// the return value, so the frame epilogue is never emitted and every entry
// is written to disk as an unterminated zstd frame (the read-side decoder
// then has to guess the frame end). Fix: loop ZSTD_e_end into the remaining
// buffer capacity until it returns 0 (frame complete), and push the appended
// epilogue bytes through the same CryptAsyncLog/UpdateLogLen path that
// LogBaseBuffer::Write() uses for ordinary compressed chunks, so encrypted
// entries keep a well-formed header/payload/trailer structure.
void LogZstdBuffer::Flush(AutoBuffer& _buff) {
    if (is_compress_ && cctx_ != nullptr
        && log_crypt_->GetLogLen((char*)buff_.Ptr(), buff_.Length()) != 0) {
        ZSTD_inBuffer input = {nullptr, 0, 0};

        for (;;) {
            size_t avail_out = buff_.MaxLength() - buff_.Length() - log_crypt_->GetTailerLen();
            if (avail_out == 0) {
                // No room left for the epilogue: degrade to upstream's
                // behavior (unterminated frame) instead of truncating the
                // already-written payload.
                break;
            }

            size_t before_len = buff_.Length() - remain_nocrypt_len_;
            ZSTD_outBuffer output = {buff_.PosPtr(), avail_out, 0};
            size_t remaining = ZSTD_compressStream2(cctx_, &output, &input, ZSTD_e_end);

            if (output.pos > 0) {
                std::string out_buffer;
                size_t last_remain_len = remain_nocrypt_len_;

                log_crypt_->CryptAsyncLog((char*)buff_.Ptr() + before_len,
                                          output.pos + remain_nocrypt_len_,
                                          out_buffer,
                                          remain_nocrypt_len_);

                buff_.Write(out_buffer.data(), out_buffer.size(), before_len);
                buff_.Length(before_len + out_buffer.size(), before_len + out_buffer.size());

                log_crypt_->UpdateLogLen((char*)buff_.Ptr(),
                                         (uint32_t)(out_buffer.size() - last_remain_len));
            }

            if (remaining == 0 || output.pos == 0) {
                break;  // Frame complete, or no progress (cannot finish here).
            }
        }
    }

    LogBaseBuffer::Flush(_buff);
}

size_t LogZstdBuffer::Compress(const void* src, size_t inLen, void* dst, size_t outLen) {
    ZSTD_inBuffer input = {src, inLen, 0};
    ZSTD_outBuffer output = {dst, outLen, 0};

    ZSTD_compressStream2(cctx_, &output, &input, ZSTD_e_flush);

    return output.pos;
}

bool LogZstdBuffer::__Reset() {
    if (!LogBaseBuffer::__Reset()) {
        return false;
    }

    if (is_compress_) {
        ZSTD_CCtx_reset(cctx_, ZSTD_reset_session_only);
    }

    return true;
}

char LogZstdBuffer::__GetMagicSyncStart() {
    return is_crypt_ ? LogMagicNum::kMagicSyncZstdStart : LogMagicNum::kMagicSyncNoCryptZstdStart;
}

char LogZstdBuffer::__GetMagicAsyncStart() {
    return is_crypt_ ? LogMagicNum::kMagicAsyncZstdStart : LogMagicNum::kMagicAsyncNoCryptZstdStart;
}

}  // namespace xlog
}  // namespace mars
