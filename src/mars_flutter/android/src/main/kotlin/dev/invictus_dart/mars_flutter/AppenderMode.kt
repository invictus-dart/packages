package dev.invictus_dart.mars_flutter

import com.tencent.mars.xlog.Xlog

enum class AppenderMode(internal val value: Int) {
    ASYNC(Xlog.AppednerModeAsync),
    SYNC(Xlog.AppednerModeSync),
}