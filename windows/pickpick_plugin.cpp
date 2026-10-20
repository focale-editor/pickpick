#include "pickpick_plugin.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>

#include <utility>

namespace pickpick {
namespace {

// Plugin-specific class name avoids collisions with the host's runner windows.
constexpr wchar_t kWindowClass[] = L"PickpickScreenColorWindow";

// Uses physical desktop coordinates even in hosts with legacy DPI settings.
class PhysicalCoordinates final {
 public:
  PhysicalCoordinates()
      : previous_(SetThreadDpiAwarenessContext(
            DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {}
  ~PhysicalCoordinates() {
    if (previous_) {
      SetThreadDpiAwarenessContext(previous_);
    }
  }

 private:
  DPI_AWARENESS_CONTEXT previous_;
};

}  // namespace

void PickpickPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "app.focaleeditor/pickpick",
          &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<PickpickPlugin>();
  channel->SetMethodCallHandler(
      [instance = plugin.get()](const auto& call, auto result) {
        instance->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}

PickpickPlugin::~PickpickPlugin() {
  // Drop the callback before closing: destruction can re-enter WindowProc.
  result_.reset();
  CloseWindow();
}

void PickpickPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() != "pickColor") {
    result->NotImplemented();
    return;
  }
  if (result_) {
    result->Success();
    return;
  }
  result_ = std::move(result);
  Start();
}

void PickpickPlugin::Start() {
  const PhysicalCoordinates coordinates;
  const HINSTANCE instance = GetModuleHandleW(nullptr);
  WNDCLASSW window_class{};
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = instance;
  window_class.hCursor = LoadCursorW(nullptr, IDC_CROSS);
  window_class.hbrBackground =
      static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
  window_class.lpszClassName = kWindowClass;
  if (!RegisterClassW(&window_class) &&
      GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
    Complete(false, "Cannot register the native picker window.");
    return;
  }
  previous_foreground_ = GetForegroundWindow();
  window_ = CreateWindowExW(
      WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW, kWindowClass,
      L"Pick a screen color — click to select, Escape to cancel", WS_POPUP,
      GetSystemMetrics(SM_XVIRTUALSCREEN), GetSystemMetrics(SM_YVIRTUALSCREEN),
      GetSystemMetrics(SM_CXVIRTUALSCREEN), GetSystemMetrics(SM_CYVIRTUALSCREEN),
      nullptr, nullptr, instance, this);
  if (!window_) {
    Complete(false, "Cannot create the native picker window.");
    return;
  }
  // Alpha zero passes mouse input to other applications. Alpha one keeps
  // clicks in this window; it becomes fully transparent before reading.
  if (!SetLayeredWindowAttributes(window_, 0, 1, LWA_ALPHA)) {
    Complete(false, "Cannot prepare the native picker window.");
    return;
  }
  ShowWindow(window_, SW_SHOW);
  SetForegroundWindow(window_);
  SetFocus(window_);
  if (GetForegroundWindow() != window_) {
    Complete(false, "The screen picker could not receive input focus.");
    return;
  }
  ready_ = true;
  SetCursor(LoadCursorW(nullptr, IDC_CROSS));
  // Do not leave a request open indefinitely after a desktop/session switch.
  if (!SetTimer(window_, 1, 5 * 60 * 1000, nullptr)) {
    Complete(false, "Cannot start the native picker timeout.");
  }
}

void PickpickPlugin::CloseWindow() {
  ready_ = false;
  pressed_ = false;
  const HWND window = std::exchange(window_, nullptr);
  const HWND previous = std::exchange(previous_foreground_, nullptr);
  if (!window) {
    return;
  }
  const bool restore_focus = GetForegroundWindow() == window;
  if (GetCapture() == window) {
    ReleaseCapture();
  }
  KillTimer(window, 1);
  ShowWindow(window, SW_HIDE);
  DestroyWindow(window);
  if (restore_focus && IsWindow(previous)) {
    SetForegroundWindow(previous);
  }
}

void PickpickPlugin::Complete(bool sample, const char* error) {
  if (!result_) {
    return;
  }
  const PhysicalCoordinates coordinates;
  auto result = std::move(result_);
  POINT position{};
  COLORREF color = CLR_INVALID;
  if (sample && !error) {
    if (!GetPhysicalCursorPos(&position)) {
      error = "Cannot locate the selected screen pixel.";
    } else if (!SetLayeredWindowAttributes(window_, 0, 0, LWA_ALPHA)) {
      error = "Cannot hide the screen picker before sampling.";
    } else if (FAILED(DwmFlush())) {
      error = "Cannot synchronize the desktop compositor.";
    } else {
      // Keep focus and capture until the read finishes. Destroying the window
      // first would reactivate the host and could change the selected pixel.
      const HDC desktop = GetDC(nullptr);
      if (!desktop) {
        error = "Cannot access the selected screen pixel.";
      } else {
        color = GetPixel(desktop, position.x, position.y);
        ReleaseDC(nullptr, desktop);
        if (color == CLR_INVALID) {
          error = "Cannot read the selected screen pixel.";
        }
      }
    }
  }
  CloseWindow();
  if (error) {
    result->Error("screen_color", error);
    return;
  }
  if (!sample) {
    result->Success();
    return;
  }
  result->Success(flutter::EncodableValue(flutter::EncodableList{
      flutter::EncodableValue(GetRValue(color) / 255.0),
      flutter::EncodableValue(GetGValue(color) / 255.0),
      flutter::EncodableValue(GetBValue(color) / 255.0)}));
}

LRESULT CALLBACK PickpickPlugin::WindowProc(
    HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    const auto* creation = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(creation->lpCreateParams));
  }
  auto* picker = reinterpret_cast<PickpickPlugin*>(
      GetWindowLongPtrW(window, GWLP_USERDATA));
  if (!picker) {
    return DefWindowProcW(window, message, wparam, lparam);
  }
  switch (message) {
    case WM_SETCURSOR:
      SetCursor(LoadCursorW(nullptr, IDC_CROSS));
      return TRUE;
    case WM_LBUTTONDOWN:
      picker->pressed_ = true;
      SetCapture(window);
      return 0;
    case WM_LBUTTONUP:
      if (picker->pressed_) {
        picker->Complete(true);
      }
      return 0;
    case WM_RBUTTONUP:
    case WM_CLOSE:
    case WM_CANCELMODE:
      picker->Complete(false);
      return 0;
    case WM_KEYUP:
      if (wparam == VK_ESCAPE) {
        picker->Complete(false);
        return 0;
      }
      break;
    case WM_ACTIVATE:
      if (picker->ready_ && LOWORD(wparam) == WA_INACTIVE) {
        picker->Complete(false);
        return 0;
      }
      break;
    case WM_CAPTURECHANGED:
      if (picker->ready_ && picker->pressed_) {
        picker->Complete(false);
        return 0;
      }
      break;
    case WM_DISPLAYCHANGE:
      picker->Complete(false, "The display configuration changed during selection.");
      return 0;
    case WM_TIMER:
      picker->Complete(false, "Screen color selection timed out.");
      return 0;
    case WM_NCDESTROY:
      SetWindowLongPtrW(window, GWLP_USERDATA, 0);
      break;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

}  // namespace pickpick
