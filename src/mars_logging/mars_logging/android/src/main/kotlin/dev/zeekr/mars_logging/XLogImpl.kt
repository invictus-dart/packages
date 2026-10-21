package dev.zeekr.mars_logging

class XLogImpl : XLogHostApi {
    override fun open(
        mode: AppenderModeApi,
        level: XLogLevelApi,
        logsDir: String,
        cacheDir: String,
        cacheDays: Long,
        namePrefix: String,
        compressMode: CompressModeApi,
        compressLevel: CompressLevelApi,
        pubKey: String,
        useConsole: Boolean,
        maxFileSize: Long,
        maxAliveDuration: Long
    ) {
        XLog.open(
            mode.impl,
            level.impl,
            logsDir,
            cacheDir,
            cacheDays.toInt(),
            namePrefix,
            compressMode.impl,
            compressLevel.impl,
            pubKey,
            useConsole,
            maxFileSize,
            maxAliveDuration,
        )
    }

    override fun flush(isSync: Boolean) {
        XLog.flush(isSync)
    }

    override fun close() {
        XLog.close()
    }

    override fun verbose(tag: String, message: String) {
        XLog.verbose(tag, message)
    }

    override fun debug(tag: String, message: String) {
        XLog.debug(tag, message)
    }

    override fun info(tag: String, message: String) {
        XLog.info(tag, message)
    }

    override fun warning(tag: String, message: String) {
        XLog.warning(tag, message)
    }

    override fun error(tag: String, message: String) {
        XLog.error(tag, message)
    }

    override fun fatal(tag: String, message: String) {
        XLog.fatal(tag, message)
    }
}
