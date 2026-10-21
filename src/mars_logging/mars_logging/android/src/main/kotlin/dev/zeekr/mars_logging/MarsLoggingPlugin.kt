package dev.zeekr.mars_logging

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** MarsLoggingPlugin */
class MarsLoggingPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val binaryMessenger = binding.binaryMessenger
        val xlogImpl = XLogImpl()
        XLogHostApi.setUp(binaryMessenger, xlogImpl)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val binaryMessenger = binding.binaryMessenger
        XLogHostApi.setUp(binaryMessenger, null)
    }
}
