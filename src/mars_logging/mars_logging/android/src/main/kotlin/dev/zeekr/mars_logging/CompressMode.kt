package dev.zeekr.mars_logging

import com.tencent.mars.xlog.Xlog

enum class CompressMode(internal val value: Int) {
    ZLIB(Xlog.ZLIB_MODE),
    ZSTD(Xlog.ZSTD_MODE),
}

internal val CompressModeApi.impl: CompressMode
    get() = when (this) {
        CompressModeApi.ZLIB -> CompressMode.ZLIB
        CompressModeApi.ZSTD -> CompressMode.ZSTD
    }
