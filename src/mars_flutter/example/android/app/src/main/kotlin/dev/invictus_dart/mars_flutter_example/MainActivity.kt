package dev.invictus_dart.mars_flutter_example

import android.os.Bundle
import dev.invictus_dart.mars_flutter.AppenderMode
import dev.invictus_dart.mars_flutter.CompressLevel
import dev.invictus_dart.mars_flutter.CompressMode
import dev.invictus_dart.mars_flutter.LogLevel
import dev.invictus_dart.mars_flutter.xlog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.util.PathUtils
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filesDir = PathUtils.getFilesDir(applicationContext).run { File(this) }
        val logsDir = filesDir.resolve("logs")
        val cacheDir = logsDir.resolve("cache")
        xlog.open(
            mode = AppenderMode.ASYNC,
            level = if (BuildConfig.DEBUG) LogLevel.DEBUG else LogLevel.INFO,
            logsDir = logsDir.path,
            cacheDir = cacheDir.path,
            cacheDays = 0,
            namePrefix = "log",
            compressMode = CompressMode.ZSTD,
            compressLevel = CompressLevel.LEVEL6,
            pubKey = "f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc",
            useConsole = BuildConfig.DEBUG,
            maxFileSize = 10 * 1024 * 1024L,
            maxAliveDuration = 30 * 24 * 60 * 60L
        )
    }

    override fun onDestroy() {
        xlog.close()
        super.onDestroy()
    }
}
