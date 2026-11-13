import Flutter
import UIKit
import mars_flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
#if DEBUG
        let level = LogLevel.debug
        let useConsole = true
#else
        let level = LogLevel.info
        let useConsole = false
#endif
        let filesPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let filesUrl = URL.init(fileURLWithPath: filesPath)
        let logsUrl = filesUrl.appendingPathComponent("logs")
        let cacheUrl = logsUrl.appendingPathComponent("cache")
        try? xlog.open(
            mode: .async,
            level: level,
            logsDir: logsUrl.path,
            cacheDir: cacheUrl.path,
            cacheDays: 0,
            namePrefix: "log",
            compressMode: .zstd,
            compressLevel: .level6,
            pubKey: "f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc",
            useConsole: useConsole,
            maxFileSize: 10 * 1024 * 1024,
            maxAliveDuration: 30 * 24 * 60 * 60
        )
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        try? xlog.close()
    }
}
