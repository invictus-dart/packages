package dev.zeekr.mars_logging

import com.tencent.mars.xlog.Xlog

enum class XLogLevel(val value: Int) {
    ALL(Xlog.LEVEL_ALL),
    VERBOSE(Xlog.LEVEL_VERBOSE),
    DEBUG(Xlog.LEVEL_DEBUG),
    INFO(Xlog.LEVEL_INFO),
    WARNING(Xlog.LEVEL_WARNING),
    ERROR(Xlog.LEVEL_ERROR),
    FATAL(Xlog.LEVEL_FATAL),
    NONE(Xlog.LEVEL_NONE),
}

internal val XLogLevelApi.impl: XLogLevel
    get() = when (this) {
        XLogLevelApi.ALL -> XLogLevel.ALL
        XLogLevelApi.VERBOSE -> XLogLevel.VERBOSE
        XLogLevelApi.DEBUG -> XLogLevel.DEBUG
        XLogLevelApi.INFO -> XLogLevel.INFO
        XLogLevelApi.WARNING -> XLogLevel.WARNING
        XLogLevelApi.ERROR -> XLogLevel.ERROR
        XLogLevelApi.FATAL -> XLogLevel.FATAL
        XLogLevelApi.NONE -> XLogLevel.NONE
    }
