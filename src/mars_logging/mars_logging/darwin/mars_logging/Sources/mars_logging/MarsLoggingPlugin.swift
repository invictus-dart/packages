#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import Cocoa
import FlutterMacOS
#else
#error("Unsupported OS")
#endif

public class MarsLoggingPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MarsLoggingPlugin(with: registrar)
        registrar.publish(instance)
    }
    
    init(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
        let messenger = registrar.messenger()
#else
        let messenger = registrar.messenger
#endif
        let xlogImpl = XLogImpl()
        XLogHostApiSetup.setUp(binaryMessenger: messenger, api: xlogImpl)
    }
    
    public func detachFromEngine(for registrar: any FlutterPluginRegistrar) {
#if os(iOS)
        let messenger = registrar.messenger()
#else
        let messenger = registrar.messenger
#endif
        XLogHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    }
}
