#include "include/pickpick/pickpick_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pickpick_plugin.h"

void PickpickPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pickpick::PickpickPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
