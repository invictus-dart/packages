#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import Cocoa
import FlutterMacOS
#else
#error("Unsupported platform.")
#endif

public class MarsFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MarsFlutterPlugin(with: registrar)
        registrar.publish(instance)
    }
    
    init(with registrar: FlutterPluginRegistrar) {}
    
    public func detachFromEngine(for registrar: any FlutterPluginRegistrar) {}
}
