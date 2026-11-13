package dev.invictus_dart.mars_flutter

import com.sun.jna.Memory
import com.sun.jna.NativeLong
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.stackTraceToString

val xlog: Xlog get() = Xlog.INSTANCE

/** Native Android counterpart of the Dart Xlog API. */
class Xlog private constructor() {
    companion object {
        internal val INSTANCE: Xlog = Xlog()
    }

    @JvmOverloads
    fun open(
        mode: AppenderMode = AppenderMode.ASYNC,
        level: LogLevel = LogLevel.ALL,
        logsDir: String,
        cacheDir: String,
        cacheDays: Int = 0,
        namePrefix: String? = null,
        compressMode: CompressMode = CompressMode.ZLIB,
        compressLevel: CompressLevel = CompressLevel.LEVEL6,
        pubKey: String? = null,
        useConsole: Boolean = false,
        maxFileSize: Long = 0,
        maxAliveDuration: Long = 10L * 24 * 60 * 60,
    ) {
        MarsLibrary.INSTANCE.mars_xlog_xlogger_set_level(level.value)
        MarsLibrary.INSTANCE.mars_xlog_appender_set_console_log(if (useConsole) 1 else 0)
        MarsLibrary.INSTANCE.mars_xlog_appender_set_max_file_size(maxFileSize)
        MarsLibrary.INSTANCE.mars_xlog_appender_set_max_alive_duration(maxAliveDuration)
        MarsLibrary.INSTANCE.mars_xlog_appender_open(
            mode.value,
            logsDir,
            cacheDir,
            cacheDays,
            namePrefix,
            compressMode.value,
            compressLevel.value,
            pubKey,
        )
    }

    /** Flushes buffered logs to disk, blocking the calling thread. */
    fun flushSync() {
        MarsLibrary.INSTANCE.mars_xlog_appender_flush_sync()
    }

    /** Runs the blocking flush on the IO dispatcher. */
    suspend fun flush() = withContext(Dispatchers.IO) { this@Xlog.flushSync() }

    fun close() {
        MarsLibrary.INSTANCE.mars_xlog_appender_close()
    }

    @JvmOverloads
    fun write(level: LogLevel, tag: String, message: String, error: Throwable? = null) {
        if (MarsLibrary.INSTANCE.mars_xlog_xlogger_is_enabled_for(level.value) == 0) return

        val element = error?.stackTrace?.firstOrNull()
        val messageBuilder = StringBuilder(message)
        if (error != null) {
            val stackTrace = error.stackTraceToString()
            messageBuilder.appendLine(stackTrace)
        }
        MarsLibrary.INSTANCE.mars_xlog_xlogger_write(
            level.value,
            tag,
            element?.fileName,
            element?.lineNumber ?: 0,
            element?.methodName,
            messageBuilder.toString(),
        )
    }

    @JvmOverloads
    fun verbose(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.VERBOSE, tag, message, error)

    @JvmOverloads
    fun debug(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.DEBUG, tag, message, error)

    @JvmOverloads
    fun info(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.INFO, tag, message, error)

    @JvmOverloads
    fun warn(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.WARN, tag, message, error)

    @JvmOverloads
    fun error(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.ERROR, tag, message, error)

    @JvmOverloads
    fun fatal(tag: String, message: String, error: Throwable? = null) =
        write(LogLevel.FATAL, tag, message, error)

    /** Decodes an xlog file image, blocking the calling thread. */
    @JvmOverloads
    fun decodeSync(input: ByteArray, privKey: String? = null): ByteArray {
        val buffer = MarsLibrary.INSTANCE.mars_create_buffer()
            ?: throw IllegalStateException("mars_create_buffer failed")
        try {
            val statusCode = MarsLibrary.INSTANCE.mars_xlog_decode(
                input,
                NativeLong(input.size.toLong()),
                buffer,
                privKey,
            )
            check(statusCode == 0) { "decode failed: $statusCode" }

            val expectedSize = MarsLibrary.INSTANCE.mars_read_buffer(
                buffer,
                null,
                NativeLong(0),
            ).toLong()
            if (expectedSize == 0L) return ByteArray(0)
            check(expectedSize <= Int.MAX_VALUE) { "decoded log is too large: $expectedSize" }

            val output = Memory(expectedSize)
            val actualSize = MarsLibrary.INSTANCE.mars_read_buffer(
                buffer,
                output,
                NativeLong(expectedSize),
            ).toLong()
            check(actualSize == expectedSize) {
                "decode failed: $actualSize/$expectedSize"
            }
            return output.getByteArray(0, expectedSize.toInt())
        } finally {
            MarsLibrary.INSTANCE.mars_free_buffer(buffer)
        }
    }

    /** Runs the blocking decoder on the IO dispatcher. */
    suspend fun decode(input: ByteArray, privKey: String? = null): ByteArray =
        withContext(Dispatchers.IO) { this@Xlog.decodeSync(input, privKey) }
}
