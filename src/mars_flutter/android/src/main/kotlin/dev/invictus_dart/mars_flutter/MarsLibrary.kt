package dev.invictus_dart.mars_flutter

import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.NativeLong
import com.sun.jna.Pointer

internal interface MarsLibrary : Library {
    companion object {
        val INSTANCE: MarsLibrary = Native.load("mars", MarsLibrary::class.java)
    }

    fun mars_create_buffer(): Pointer?

    fun mars_free_buffer(buffer: Pointer?)

    fun mars_read_buffer(buffer: Pointer, output: Pointer?, size: NativeLong): NativeLong

    fun mars_xlog_appender_open(
        mode: Int,
        logsDir: String,
        cacheDir: String,
        cacheDays: Int,
        namePrefix: String?,
        compressMode: Int,
        compressLevel: Int,
        pubKey: String?
    )

    fun mars_xlog_appender_close()

    fun mars_xlog_appender_flush_sync()

    fun mars_xlog_appender_set_console_log(isOpen: Int)

    fun mars_xlog_appender_set_max_file_size(maxByteSize: Long)

    fun mars_xlog_appender_set_max_alive_duration(maxTimeSeconds: Long)

    fun mars_xlog_xlogger_set_level(level: Int)

    fun mars_xlog_xlogger_is_enabled_for(level: Int): Int

    fun mars_xlog_xlogger_write(
        level: Int, tag: String?, fileName: String?, line: Int, funcName: String?, message: String
    )

    fun mars_xlog_decode(input: ByteArray, size: NativeLong, buffer: Pointer, privKey: String?): Int
}
