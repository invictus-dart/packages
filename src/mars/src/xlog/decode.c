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
 *      Author: zhangchangrong
 */

// Fix: MSVC portability -- dropped <dirent.h>/<unistd.h>/<sys/stat.h>/<sys/types.h>
// (unused without the CLI main()), added <stdbool.h>/<stdint.h>. Keep this file
// ASCII-only (the build does not pass /utf-8).
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "decode.h"
#include "micro-ecc-master/uECC.h"
#include "zlib.h"
#include "zstd/lib/zstd.h"

const int MAGIC_CRYPT_START = 0x01;
const int MAGIC_COMPRESS_CRYPT_START = 0x02;

const int NEW_MAGIC_CRYPT_START = 0x03;
const int NEW_MAGIC_COMPRESS_CRYPT_START = 0x04;
const int NEW_MAGIC_COMPRESS_CRYPT_START1 = 0x05;

const int MAGIC_SYNC_ZLIB_START = 0x06;
const int MAGIC_SYNC_NO_CRYPT_ZLIB_START = 0x08;
const int MAGIC_ASYNC_ZLIB_START = 0x07;
const int MAGIC_ASYNC_NO_CRYPT_ZLIB_START = 0x09;

const int MAGIC_SYNC_ZSTD_START = 0x0A;
const int MAGIC_SYNC_NO_CRYPT_ZSTD_START = 0x0B;
const int MAGIC_ASYNC_ZSTD_START = 0x0C;
const int MAGIC_ASYNC_NO_CRYPT_ZSTD_START = 0x0D;

const int MAGIC_END = 0x00;
const int BASE_KEY = 0xCC;

const int TEA_BLOCK_LEN = 8;

// Fix: library adaptation: fatal errors return the negated upstream exit
// codes instead of calling exit() -- -2 memory, -5 output realloc, -6
// decompression, -7 invalid ECDH priv key. -1 is NOT an error (no more
// decodable segments). An ECDH segment that cannot be decrypted (NULL
// privKey -> zeroed key) is skipped with a "Get ECDH key error"
// placeholder, not an error.

// TODO (category 3 of the review, deferred; upstream has the same behavior,
// fix only when needed):
//  * zlibDecompress(): when the output buffer is exactly exhausted inflate
//    returns Z_BUF_ERROR and the loop stops with truncated output instead
//    of growing the buffer.
//  * zstdDecompress(): on error the "zstd decompress error" text is
//    memcpy'd into uncomp, which may be smaller than the text (overflow),
//    and the function still returns true.
//  * NEW_MAGIC_COMPRESS_CRYPT_START1 branch: zlibDecompress() is called
//    with tmpBufferSize (capacity) instead of tmpBufferWritePos (bytes
//    actually written).
//  * size_t/int mixing (7x C4267): compressed lengths are narrowed to
//    unsigned/uInt and decodeBuffer() returns int for size_t offsets;
//    breaks for logs > 2 GB.
//  * isGoodLogBuffer(): offset + headerLen + length + 1 can wrap around
//    size_t and bypass the bounds check (only reachable on 32-bit builds
//    with a crafted length; low risk).

bool Hex2Buffer(const char* str, size_t len, unsigned char* buffer) {
    if (NULL == str || len == 0 || len % 2 != 0) {
        return true;
    }

    char tmp[3] = {0};
    size_t i;
    for (i = 0; i < len - 1; i += 2) {
        size_t j;
        for (j = 0; j < 2; ++j) {
            tmp[j] = str[i + j];
            if (!(('0' <= tmp[j] && tmp[j] <= '9') || ('a' <= tmp[j] && tmp[j] <= 'f')
                  || ('A' <= tmp[j] && tmp[j] <= 'F'))) {
                return false;
            }
        }

        buffer[i / 2] = (unsigned char)strtol(tmp, NULL, 16);
    }
    return true;
}

void teaDecrypt(uint32_t* v, uint32_t* k) {
    uint32_t v0 = v[0], v1 = v[1], sum, i;
    const static uint32_t delta = 0x9e3779b9;
    const static uint32_t totalSum = 0x9e3779b9 << 4;
    sum = totalSum;

    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3];
    for (i = 0; i < 16; i++) {
        v1 -= ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
        v0 -= ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        sum -= delta;
    }
    v[0] = v0;
    v[1] = v1;
}

bool isGoodLogBuffer(const char* buffer, size_t bufferSize, size_t offset, int count) {
    if (offset == bufferSize) {
        return true;
    }

    int cryptKeyLen = 0;
    int headerLen = 0;
    if (MAGIC_CRYPT_START == buffer[offset] || MAGIC_COMPRESS_CRYPT_START == buffer[offset]) {
        headerLen = 1 + 4;
    } else if (NEW_MAGIC_CRYPT_START == buffer[offset] || NEW_MAGIC_COMPRESS_CRYPT_START == buffer[offset]
               || NEW_MAGIC_COMPRESS_CRYPT_START1 == buffer[offset]) {
        headerLen = 1 + 2 + 1 + 1 + 4;
    } else if (MAGIC_ASYNC_ZLIB_START == buffer[offset] || MAGIC_SYNC_ZLIB_START == buffer[offset]
               || MAGIC_SYNC_NO_CRYPT_ZLIB_START == buffer[offset] || MAGIC_ASYNC_NO_CRYPT_ZLIB_START == buffer[offset]
               || MAGIC_ASYNC_ZSTD_START == buffer[offset] || MAGIC_SYNC_ZSTD_START == buffer[offset]
               || MAGIC_SYNC_NO_CRYPT_ZSTD_START == buffer[offset]
               || MAGIC_ASYNC_NO_CRYPT_ZSTD_START == buffer[offset]) {
        headerLen = 1 + 2 + 1 + 1 + 4 + 64;
        cryptKeyLen = 64;
    } else {
        // '_buffer[%d]:%d != MAGIC_NUM_START'%(_offset, _buffer[_offset]))
        return false;
    }

    if (offset + headerLen + 1 + 1 > bufferSize) {
        // 'offset:%d > len(buffer):%d'%(_offset, len(_buffer))
        return false;
    }

    uint32_t length;
    memcpy(&length, &buffer[offset + headerLen - cryptKeyLen - 4], 4);

    if (offset + headerLen + length + 1 > bufferSize) {
        // 'log length:%d, end pos %d > len(buffer):%d' % (length, _offset + headerLen + length + 1, len(_buffer))
        return false;
    }
    if (MAGIC_END != buffer[offset + headerLen + length]) {
        // 'log length:%d, buffer[%d]:%d != MAGIC_END'%(length, _offset + headerLen + length, _buffer[_offset +
        // headerLen + length])
        return false;
    }

    if (1 >= count) {
        return true;
    } else {
        return isGoodLogBuffer(buffer, bufferSize, offset + headerLen + length + 1, count - 1);
    }

    return true;
}

size_t getLogStartPos(const char* buffer, size_t bufferSize, int count) {
    size_t offset = 0;
    while (1) {
        if (offset >= bufferSize) {
            break;
        }
        if (buffer[offset] >= MAGIC_CRYPT_START && buffer[offset] <= MAGIC_ASYNC_NO_CRYPT_ZSTD_START) {
            if (isGoodLogBuffer(buffer, bufferSize, offset, count)) {
                return offset;
            }
        }
        offset += 1;
    }
    return -1;
}

// Fix: returns false on OOM instead of exit(5); the output buffer stays valid.
bool appendBuffer(char** outBuffer, size_t* outBufferSize, size_t* writePos, const char* buffer, size_t bufferSize) {
    if ((*outBufferSize) - (*writePos) < bufferSize + 1)  // + 1 for last \0
    {
        char* newOutBuffer = (char*)realloc(*outBuffer, (*outBufferSize) + 2 * bufferSize);
        if (NULL == newOutBuffer) {
            fputs("Error reallocating memory", stderr);
            return false;
        }
        *outBuffer = newOutBuffer;
        *outBufferSize = (*outBufferSize) + 2 * bufferSize;
    }

    memcpy(*outBuffer + (*writePos), buffer, bufferSize);
    *writePos = (*writePos) + bufferSize;
    return true;
}

bool zstdDecompress(const char* compressedBytes, size_t compressedBytesSize, char** outBuffer, size_t* outBufferSize) {
    *outBuffer = NULL;
    *outBufferSize = 0;
    if (compressedBytesSize == 0) {
        return true;
    }

    unsigned fullLength = compressedBytesSize;
    unsigned halfLength = compressedBytesSize / 2;

    unsigned uncompLength = fullLength;
    char* uncomp = (char*)calloc(sizeof(char), uncompLength);

    ZSTD_DCtx* const dctx = ZSTD_createDCtx();

    ZSTD_inBuffer input = {compressedBytes, compressedBytesSize, 0};
    ZSTD_outBuffer output = {NULL, compressedBytesSize, 0};
    bool done = false;

    // Fix: lastPos was a never-declared file-scope global upstream; it only
    // guards this loop, so it is local here (no shared mutable state).
    size_t lastPos = 0;

    while (!done) {
        if (output.pos >= uncompLength) {
            char* uncomp2 = (char*)calloc(sizeof(char), uncompLength + halfLength);
            memcpy(uncomp2, uncomp, uncompLength);
            uncompLength += halfLength;
            free(uncomp);
            uncomp = uncomp2;
        }

        output.size = uncompLength;
        output.dst = uncomp;
        size_t decompressResult = ZSTD_decompressStream(dctx, &output, &input);
        if (lastPos == output.pos) {
            fputs("ZSTD_decompressStream error\n", stderr);
            done = true;
        }

        lastPos = output.pos;
        if (input.pos == input.size) {
            done = true;
        }

        if (input.pos == 0) {
            char* err = "zstd decompress error";
            output.pos = strnlen(err, 1024);
            memcpy(uncomp, err, output.pos);
            done = true;
        }
    }

    ZSTD_freeDCtx(dctx);

    *outBuffer = uncomp;
    *outBufferSize = output.pos;
    return true;
}

bool zlibDecompress(const char* compressedBytes, size_t compressedBytesSize, char** outBuffer, size_t* outBufferSize) {
    *outBuffer = NULL;
    *outBufferSize = 0;
    if (compressedBytesSize == 0) {
        return true;
    }

    unsigned fullLength = compressedBytesSize;
    unsigned halfLength = compressedBytesSize / 2;

    unsigned uncompLength = fullLength;
    char* uncomp = (char*)calloc(sizeof(char), uncompLength);

    z_stream strm;
    strm.next_in = (Bytef*)compressedBytes;
    strm.avail_in = compressedBytesSize;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;

    bool done = false;

    if (inflateInit2(&strm, (-MAX_WBITS)) != Z_OK) {
        free(uncomp);
        return false;
    }

    while (!done) {
        strm.next_out = (Bytef*)(uncomp + strm.total_out);
        strm.avail_out = uncompLength - strm.total_out;

        // Inflate another chunk.
        int err = inflate(&strm, Z_SYNC_FLUSH);
        // decompress success
        if (strm.total_in == compressedBytesSize) {
            break;
        }
        if (err == Z_STREAM_END || err == Z_BUF_ERROR || err == Z_DATA_ERROR) {
            done = true;
        }
        //        else if (err != Z_OK)
        //        {
        //            break;
        //        }

        // If our output buffer is too small
        if (strm.total_out >= uncompLength) {
            // Increase size of output buffer
            char* uncomp2 = (char*)calloc(sizeof(char), uncompLength + halfLength);
            memcpy(uncomp2, uncomp, uncompLength);
            uncompLength += halfLength;
            free(uncomp);
            uncomp = uncomp2;
        }
    }

    if (inflateEnd(&strm) != Z_OK) {
        free(uncomp);
        return false;
    }

    *outBuffer = uncomp;
    *outBufferSize = strm.total_out;
    return true;
}

// Fix: lastSeq was a file-scope global; now a per-decode() local passed by
// pointer so every decode() starts from seq 0.
int decodeBuffer(const char* buffer, size_t bufferSize, size_t offset, char** outBuffer, size_t* outBufferSize, size_t* writePos, const char* privKey, int* lastSeq) {
    if (offset >= bufferSize) {
        return -1;
    }

    if (!isGoodLogBuffer(buffer, bufferSize, offset, 1)) {
        size_t fixpos = getLogStartPos(buffer + offset, bufferSize - offset, 1);
        if (-1 == fixpos) {
            return -1;
        } else {
            char text[128];
            snprintf(text, sizeof(text), "[F]decode_log_file.py decode error len=%d\n", (int)fixpos);
            if (!appendBuffer(outBuffer, outBufferSize, writePos, text, strlen(text))) {
                return -5;
            }
            offset += fixpos;
        }
    }

    size_t cryptKeyLen = 0;
    size_t headerLen = 0;
    if (MAGIC_CRYPT_START == buffer[offset] || MAGIC_COMPRESS_CRYPT_START == buffer[offset]) {
        headerLen = 1 + 4;
    } else if (NEW_MAGIC_CRYPT_START == buffer[offset] || NEW_MAGIC_COMPRESS_CRYPT_START == buffer[offset]
               || NEW_MAGIC_COMPRESS_CRYPT_START1 == buffer[offset]) {
        headerLen = 1 + 2 + 1 + 1 + 4;
    } else if (MAGIC_ASYNC_ZLIB_START == buffer[offset] || MAGIC_SYNC_ZLIB_START == buffer[offset]
               || MAGIC_SYNC_NO_CRYPT_ZLIB_START == buffer[offset] || MAGIC_ASYNC_NO_CRYPT_ZLIB_START == buffer[offset]
               || MAGIC_ASYNC_ZSTD_START == buffer[offset] || MAGIC_SYNC_ZSTD_START == buffer[offset]
               || MAGIC_SYNC_NO_CRYPT_ZSTD_START == buffer[offset]
               || MAGIC_ASYNC_NO_CRYPT_ZSTD_START == buffer[offset]) {
        headerLen = 1 + 2 + 1 + 1 + 4 + 64;
        cryptKeyLen = 64;
    } else {
        char text[128];
        snprintf(text, sizeof(text), "in DecodeBuffer _buffer[%zu]:%d != MAGIC_NUM_START", offset, (int)buffer[offset]);
        if (!appendBuffer(outBuffer, outBufferSize, writePos, text, strlen(text))) {
            return -5;
        }
        return -1;
    }

    uint32_t length;
    memcpy(&length, &buffer[offset + headerLen - cryptKeyLen - 4], 4);

    int key;

    if (MAGIC_COMPRESS_CRYPT_START == buffer[offset] || MAGIC_CRYPT_START == buffer[offset]) {
        key = BASE_KEY ^ (0xff & length) ^ buffer[offset];
    } else {
        unsigned short seq;
        memcpy(&seq, &buffer[offset + headerLen - cryptKeyLen - 4 - 2 - 2], 2);
        char beginHour;
        memcpy(&beginHour, &buffer[offset + headerLen - cryptKeyLen - 4 - 1 - 1], 1);
        char endHour;
        memcpy(&endHour, &buffer[offset + headerLen - cryptKeyLen - 4 - 1], 1);

        key = BASE_KEY ^ (0xff & seq) ^ buffer[offset];

        if (seq != 0 && seq != 1 && *lastSeq != 0 && seq != (*lastSeq + 1)) {
            char text[128];
            snprintf(text, sizeof(text), "[F]decode_log_file.py log seq:%d-%d is missing\n", *lastSeq + 1, seq - 1);
            if (!appendBuffer(outBuffer, outBufferSize, writePos, text, strlen(text))) {
                return -5;
            }
        }

        if (seq != 0) {
            *lastSeq = seq;
        }
    }

    // Fix: NULL-check before memset (was after); exit(2) -> -2.
    char* tmpBuffer = (char*)realloc(NULL, length);
    if (tmpBuffer == NULL) {
        fputs("Memory error", stderr);
        return -2;
    }
    memset(tmpBuffer, 0, length);
    size_t tmpBufferSize = length;

    if (MAGIC_COMPRESS_CRYPT_START == buffer[offset] || NEW_MAGIC_COMPRESS_CRYPT_START == buffer[offset]) {
        size_t i;
        for (i = 0; i < length; i++) {
            tmpBuffer[i] = key ^ buffer[offset + headerLen + i];
        }
        char* decompBuffer;
        size_t decompBufferSize;
        if (!zlibDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
            fputs("Decompress error", stderr);
            free(tmpBuffer);
            return -6;
        }

        free(tmpBuffer);
        tmpBuffer = decompBuffer;
        tmpBufferSize = decompBufferSize;
    } else if (NEW_MAGIC_COMPRESS_CRYPT_START1 == buffer[offset]) {
        size_t readPos = 0;
        size_t readSize = 0;
        size_t tmpBufferWritePos = 0;
        while (readPos < length) {
            uint16_t singleLogLen;
            memcpy(&singleLogLen, buffer + offset + headerLen + readPos, 2);
            if (!appendBuffer(&tmpBuffer,
                              &tmpBufferSize,
                              &tmpBufferWritePos,
                              buffer + offset + headerLen + readPos + 2,
                              singleLogLen)) {
                free(tmpBuffer);
                return -5;
            }
            readSize += singleLogLen;
            readPos += singleLogLen + 2;
        }

        size_t i;
        for (i = 0; i < readSize; i++) {
            tmpBuffer[i] = key ^ tmpBuffer[i];
        }

        char* decompBuffer;
        size_t decompBufferSize;
        if (!zlibDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
            fputs("Decompress error", stderr);
            free(tmpBuffer);
            return -6;
        }

        free(tmpBuffer);
        tmpBuffer = decompBuffer;
        tmpBufferSize = decompBufferSize;
    } else if (MAGIC_SYNC_ZLIB_START == buffer[offset] || MAGIC_SYNC_NO_CRYPT_ZLIB_START == buffer[offset]
               || MAGIC_SYNC_ZSTD_START == buffer[offset] || MAGIC_SYNC_NO_CRYPT_ZSTD_START == buffer[offset]) {
        memcpy(tmpBuffer, buffer + offset + headerLen, length);
    } else if (MAGIC_ASYNC_ZLIB_START == buffer[offset] || MAGIC_ASYNC_ZSTD_START == buffer[offset]) {
        memcpy(tmpBuffer, buffer + offset + headerLen, length);
        // Fix: was a VLA (MSVC does not support them); cryptKeyLen is always 64 here.
        unsigned char clientPubKey[64];
        memcpy(clientPubKey, buffer + offset + headerLen - cryptKeyLen, cryptKeyLen);

        unsigned char svrPriKey[32] = {0};
        if (!Hex2Buffer(privKey, 64, svrPriKey)) {
            fputs("Get PRIV KEY error", stderr);
            free(tmpBuffer);
            return -7;
        }

        unsigned char ecdhKey[32] = {0};
        if (0 == uECC_shared_secret(clientPubKey, svrPriKey, ecdhKey, uECC_secp256k1())) {
            // Fix: the upstream memcpy of the error text through tmpBuffer can
            // overflow (tmpBuffer may be smaller than the text); append the
            // text directly instead.
            free(tmpBuffer);
            fputs("Get ECDH key error\n", stderr);
            const char* err = "Get ECDH key error\n";
            if (!appendBuffer(outBuffer, outBufferSize, writePos, err, strlen(err))) {
                return -5;
            }
            return offset + headerLen + length + 1;
        }

        uint32_t teaKey[4];
        memcpy(teaKey, ecdhKey, sizeof(teaKey));
        uint32_t tmp[2] = {0};
        size_t cnt = length / TEA_BLOCK_LEN;

        size_t i;
        for (i = 0; i < cnt; i++) {
            memcpy(tmp, tmpBuffer + i * TEA_BLOCK_LEN, TEA_BLOCK_LEN);
            teaDecrypt(tmp, teaKey);
            memcpy(tmpBuffer + i * TEA_BLOCK_LEN, tmp, TEA_BLOCK_LEN);
        }

        char* decompBuffer;
        size_t decompBufferSize;
        if (MAGIC_ASYNC_ZLIB_START == buffer[offset]) {
            if (!zlibDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
                fputs("Decompress error", stderr);
                free(tmpBuffer);
                return -6;
            }
        } else if (MAGIC_ASYNC_ZSTD_START == buffer[offset]) {
            if (!zstdDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
                fputs("Decompress error", stderr);
                free(tmpBuffer);
                return -6;
            }
        }

        free(tmpBuffer);
        tmpBuffer = decompBuffer;
        tmpBufferSize = decompBufferSize;
    } else if (MAGIC_ASYNC_NO_CRYPT_ZLIB_START == buffer[offset] || MAGIC_ASYNC_NO_CRYPT_ZSTD_START == buffer[offset]) {
        memcpy(tmpBuffer, buffer + offset + headerLen, length);
        char* decompBuffer;
        size_t decompBufferSize;
        if (MAGIC_ASYNC_NO_CRYPT_ZLIB_START == buffer[offset]) {
            if (!zlibDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
                fputs("Decompress error", stderr);
                free(tmpBuffer);
                return -6;
            }
        } else if (MAGIC_ASYNC_NO_CRYPT_ZSTD_START == buffer[offset]) {
            if (!zstdDecompress(tmpBuffer, tmpBufferSize, &decompBuffer, &decompBufferSize)) {
                fputs("Decompress error", stderr);
                free(tmpBuffer);
                return -6;
            }
        }

        free(tmpBuffer);
        tmpBuffer = decompBuffer;
        tmpBufferSize = decompBufferSize;
    } else {
        size_t i;
        for (i = 0; i < length; i++) {
            tmpBuffer[i] = key ^ buffer[offset + headerLen + i];
        }
    }

    if (!appendBuffer(outBuffer, outBufferSize, writePos, tmpBuffer, tmpBufferSize)) {
        free(tmpBuffer);
        return -5;
    }
    free(tmpBuffer);

    return offset + headerLen + length + 1;
}

int decode(const char* buffer, size_t bufferSize, char** outBuffer, size_t* outBufferSize, const char* privKey) {
    size_t startPos = getLogStartPos(buffer, bufferSize, 2);
    if (-1 == startPos) {
        return -1;
    }

    size_t tmpBufferSize = bufferSize * 6;
    char* tmpBuffer = (char*)realloc(*outBuffer, tmpBufferSize);
    // Fix: was unchecked; a NULL from realloc would crash below.
    if (NULL == tmpBuffer) {
        return -2;
    }
    size_t writePos = 0;
    // Fix: lastSeq was a file-scope global; now a per-call local so every
    // decode() starts from seq 0.
    int lastSeq = 0;
    int statusCode;
    while (1) {
        int nextPos = decodeBuffer(buffer, bufferSize, startPos, &tmpBuffer, &tmpBufferSize, &writePos, privKey, &lastSeq);
        if (nextPos < 0) {
            statusCode = nextPos < -1 ? nextPos : 0;
            break;
        }
        startPos = nextPos;
    }

    *outBuffer = tmpBuffer;
    *outBufferSize = writePos;
    return statusCode;
}
