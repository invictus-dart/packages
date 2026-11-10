package dev.invictus_dart.mars_flutter

import com.tencent.mars.xlog.Log
import com.tencent.mars.xlog.Xlog

object Xlog {
    fun open(
        mode: AppenderMode,
        level: LogLevel,
        logsDir: String,
        cacheDir: String,
        cacheDays: Int,
        namePrefix: String,
        compressMode: CompressMode,
        compressLevel: CompressLevel,
        pubKey: String,
        useConsole: Boolean,
        maxFileSize: Long,
        maxAliveDuration: Long,
    ) {
        System.loadLibrary("c++_shared")
        System.loadLibrary("mars")

        val imp = Xlog()
        Log.setLogImp(imp)
        Log.setConsoleLogOpen(useConsole)
        Log.setMaxFileSize(maxFileSize)
        Log.setMaxAliveTime(maxAliveDuration)
        Log.appenderOpen(
            mode.value,
            level.value,
            logsDir,
            cacheDir,
            cacheDays,
            namePrefix,
            compressMode.value,
            compressLevel.value,
            pubKey
        )
    }

    fun flush(isSync: Boolean) {
        Log.appenderFlushSync(isSync)
    }

    fun close() {
        Log.appenderClose()
    }

    fun verbose(tag: String, message: String) {
        Log.v(tag, message)
    }

    fun debug(tag: String, message: String) {
        Log.d(tag, message)
    }

    fun info(tag: String, message: String) {
        Log.i(tag, message)
    }

    fun warning(tag: String, message: String) {
        Log.w(tag, message)
    }

    fun error(tag: String, message: String) {
        Log.e(tag, message)
    }

    fun fatal(tag: String, message: String) {
        Log.f(tag, message)
    }
}