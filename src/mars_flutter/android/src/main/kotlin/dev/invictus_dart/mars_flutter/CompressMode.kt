package dev.invictus_dart.mars_flutter

import com.tencent.mars.xlog.Xlog

enum class CompressMode(internal val value: Int) {
    ZLIB(Xlog.ZLIB_MODE), ZSTD(Xlog.ZSTD_MODE),
}