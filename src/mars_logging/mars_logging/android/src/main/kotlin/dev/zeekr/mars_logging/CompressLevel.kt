package dev.zeekr.mars_logging

import com.tencent.mars.xlog.Xlog

enum class CompressLevel(internal val value: Int) {
    LEVEL1(Xlog.COMPRESS_LEVEL1),
    LEVEL2(Xlog.COMPRESS_LEVEL2),
    LEVEL3(Xlog.COMPRESS_LEVEL3),
    LEVEL4(Xlog.COMPRESS_LEVEL4),
    LEVEL5(Xlog.COMPRESS_LEVEL5),
    LEVEL6(Xlog.COMPRESS_LEVEL6),
    LEVEL7(Xlog.COMPRESS_LEVEL7),
    LEVEL8(Xlog.COMPRESS_LEVEL8),
    LEVEL9(Xlog.COMPRESS_LEVEL9),
}

internal val CompressLevelApi.impl: CompressLevel
    get() = when (this) {
        CompressLevelApi.LEVEL1 -> CompressLevel.LEVEL1
        CompressLevelApi.LEVEL2 -> CompressLevel.LEVEL2
        CompressLevelApi.LEVEL3 -> CompressLevel.LEVEL3
        CompressLevelApi.LEVEL4 -> CompressLevel.LEVEL4
        CompressLevelApi.LEVEL5 -> CompressLevel.LEVEL5
        CompressLevelApi.LEVEL6 -> CompressLevel.LEVEL6
        CompressLevelApi.LEVEL7 -> CompressLevel.LEVEL7
        CompressLevelApi.LEVEL8 -> CompressLevel.LEVEL8
        CompressLevelApi.LEVEL9 -> CompressLevel.LEVEL9
    }
