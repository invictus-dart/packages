#include "include/mars_flutter/mars_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mars_flutter_plugin.h"

void MarsFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mars_flutter::MarsFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
