//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_tts/flutter_tts_plugin.h>
#include <local_auth_windows/local_auth_plugin.h>
#include <speech_to_text_windows/speech_to_text_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterTtsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterTtsPlugin"));
  LocalAuthPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalAuthPlugin"));
  SpeechToTextWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SpeechToTextWindows"));
}
