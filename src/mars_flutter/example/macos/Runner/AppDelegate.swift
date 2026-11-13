import Cocoa
import FlutterMacOS
import mars_flutter

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
#if DEBUG
        let level = LogLevel.debug
        let useConsole = true
#else
        let level = LogLevel.info
        let useConsole = false
#endif
        let filesPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        // In a non-sandboxed app, these are shared directories where applications are
        // expected to use its bundle ID as a subdirectory. (For non-sandboxed apps,
        // adding the extra path is harmless).
        // This is not done for iOS, for compatibility with older versions of the
        // plugin.
        let filesUrl = URL.init(fileURLWithPath: filesPath).appendingPathComponent(Bundle.main.bundleIdentifier!)
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
    }
    
    override func applicationWillTerminate(_ notification: Notification) {
        try? xlog.close()
    }
}
