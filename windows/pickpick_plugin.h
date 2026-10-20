#ifndef FLUTTER_PLUGIN_PICKPICK_PLUGIN_H_
#define FLUTTER_PLUGIN_PICKPICK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <memory>

namespace pickpick {

// Owns a temporary native input window and reads only the selected pixel.
class PickpickPlugin final : public flutter::Plugin {
 public:
  // Registers the method channel independently of the application's views.
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  PickpickPlugin() = default;
  ~PickpickPlugin() override;

  PickpickPlugin(const PickpickPlugin&) = delete;
  PickpickPlugin& operator=(const PickpickPlugin&) = delete;

 private:
  // Dispatches native calls on Flutter's platform thread.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Opens an almost transparent, input-receiving window over all monitors.
  void Start();

  // Destroys the input window and releases its focus and mouse capture.
  void CloseWindow();

  // Completes cancellation, selection or a failed native operation exactly once.
  void Complete(bool sample, const char* error = nullptr);

  // Routes input and lifecycle messages to the active request.
  static LRESULT CALLBACK WindowProc(HWND window, UINT message,
                                     WPARAM wparam, LPARAM lparam);

  // Window owned exclusively by the pending request.
  HWND window_ = nullptr;

  // Previously active window, restored only when the picker still owns focus.
  HWND previous_foreground_ = nullptr;

  // Whether startup has completed and focus loss should cancel the request.
  bool ready_ = false;

  // Prevents a mouse release without a matching press from selecting a color.
  bool pressed_ = false;

  // Completion callback retained until selection, cancellation or disposal.
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result_;
};

}  // namespace pickpick

#endif  // FLUTTER_PLUGIN_PICKPICK_PLUGIN_H_
