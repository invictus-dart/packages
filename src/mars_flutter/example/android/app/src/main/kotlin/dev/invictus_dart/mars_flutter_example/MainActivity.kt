package dev.invictus_dart.mars_flutter_example

import android.os.Bundle
import dev.invictus_dart.mars_flutter.AppenderMode
import dev.invictus_dart.mars_flutter.CompressLevel
import dev.invictus_dart.mars_flutter.CompressMode
import dev.invictus_dart.mars_flutter.LogLevel
import dev.invictus_dart.mars_flutter.Xlog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.util.PathUtils

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mode = AppenderMode.ASYNC
        val level = if (BuildConfig.DEBUG) LogLevel.DEBUG
        else LogLevel.INFO
        val filesDir = PathUtils.getFilesDir(applicationContext)
        val logsDir = "$filesDir/logs"
        val cacheDir = "$filesDir/cache"
        val cacheDays = 0
        val namePrefix = "log"
        val compressMode = CompressMode.ZLIB
        val compressLevel = CompressLevel.LEVEL6
        val pubKey =
            "f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc"
        val useConsole = BuildConfig.DEBUG
        val maxFileSize = 10 * 1024 * 1024L
        val maxAliveDuration = 30 * 24 * 60 * 60L
        Xlog.open(
            mode,
            level,
            logsDir,
            cacheDir,
            cacheDays,
            namePrefix,
            compressMode,
            compressLevel,
            pubKey,
            useConsole,
            maxFileSize,
            maxAliveDuration
        )
    }

    override fun onDestroy() {
        Xlog.close()
        super.onDestroy()
    }
}
