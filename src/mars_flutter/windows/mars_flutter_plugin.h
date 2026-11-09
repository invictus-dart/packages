#ifndef FLUTTER_PLUGIN_MARS_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_MARS_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mars_flutter {

class MarsFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MarsFlutterPlugin();

  virtual ~MarsFlutterPlugin();

  // Disallow copy and assign.
  MarsFlutterPlugin(const MarsFlutterPlugin&) = delete;
  MarsFlutterPlugin& operator=(const MarsFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mars_flutter

#endif  // FLUTTER_PLUGIN_MARS_FLUTTER_PLUGIN_H_
