package dev.zeekr.mars_logging

import com.tencent.mars.xlog.Xlog

enum class AppenderMode(internal val value: Int) {
    ASYNC(Xlog.AppednerModeAsync),
    SYNC(Xlog.AppednerModeSync),
}

internal val AppenderModeApi.impl: AppenderMode
    get() = when (this) {
        AppenderModeApi.ASYNC -> AppenderMode.ASYNC
        AppenderModeApi.SYNC -> AppenderMode.SYNC
    }
