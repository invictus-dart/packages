package dev.invictus_dart.mars_flutter

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