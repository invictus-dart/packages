package dev.zeekr.mars_logging_example

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        val mode = AppenderMode.ASYNC
//        val level = if (BuildConfig.DEBUG) XLogLevel.DEBUG
//        else XLogLevel.INFO
//        val filesDir = PathUtils.getFilesDir(applicationContext)
//        val logsDir = "$filesDir/logs"
//        val cacheDir = "$filesDir/cache"
//        val cacheDays = 0
//        val namePrefix = "log"
//        val pubKey = ""
//        val useConsole = BuildConfig.DEBUG
//        val maxFileSize = 10 * 1024 * 1024L
//        val maxAliveDuration = 30 * 24 * 60 * 60L
//        XLog.open(
//            mode,
//            level,
//            logsDir,
//            cacheDir,
//            cacheDays,
//            namePrefix,
//            CompressMode.ZLIB,
//            CompressLevel.LEVEL6,
//            pubKey,
//            useConsole,
//            maxFileSize,
//            maxAliveDuration
//        )
    }

    override fun onDestroy() {
//        XLog.close()
        super.onDestroy()
    }
}
