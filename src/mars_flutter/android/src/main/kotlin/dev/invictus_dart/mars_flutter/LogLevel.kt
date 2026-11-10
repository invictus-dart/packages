package dev.invictus_dart.mars_flutter

import com.tencent.mars.xlog.Xlog

enum class LogLevel(val value: Int) {
    ALL(Xlog.LEVEL_ALL),
    VERBOSE(Xlog.LEVEL_VERBOSE),
    DEBUG(Xlog.LEVEL_DEBUG),
    INFO(Xlog.LEVEL_INFO),
    WARNING(Xlog.LEVEL_WARNING),
    ERROR(Xlog.LEVEL_ERROR),
    FATAL(Xlog.LEVEL_FATAL),
    NONE(Xlog.LEVEL_NONE),
}