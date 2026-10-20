<p align="center">
  <img src="screenshots/overview.png" alt="Pickpick package illustration" width="180">
</p>

# Pickpick

Pickpick is a Flutter plugin for selecting a color anywhere on screen through a native desktop or browser picker. It returns an opaque sRGB color without capturing desktop screenshots in your application.

## Supported features

- Screen color selection on Linux, macOS, Windows, and supported web browsers.
- A small API: synchronous `available` detection and asynchronous `pick()`.
- Opaque sRGB results as `0xFFRRGGBB` integers, ready to use with Flutter's `Color`.
- Cancellation represented by `null`, with one pending request shared by all clients in the same Dart isolate.
- Validation of platform color responses and propagation of permission, portal, native-channel, and browser errors.
- Automatic Flutter plugin registration, with CocoaPods and Swift Package Manager support on macOS.

## Platform support

| Platform | Implementation | Requirements |
| --- | --- | --- |
| Linux | XDG Desktop Portal `Screenshot.PickColor` | Session D-Bus and a portal backend implementing Screenshot version 2+, on Wayland or X11 |
| macOS | `NSColorSampler` | macOS 12+, CocoaPods or Swift Package Manager |
| Windows | Native Win32 input window and `GetPixel` | Windows 10+, interactive desktop |
| Web | Browser `EyeDropper` | Secure context, supporting browser, direct user activation |
| Android, iOS | Unavailable | `available` is `false`; `pick()` throws `UnsupportedError` |

## Usage

```dart
import 'package:flutter/painting.dart';
import 'package:pickpick/pickpick.dart';

const Pickpick picker = Pickpick();

Future<Color?> pickScreenColor() async {
  if (!picker.available) {
    return null;
  }
  final int? argb = await picker.pick();
  return argb == null ? null : Color(argb);
}
```

Invoke `pick()` directly from a button or another user gesture. In browsers,
awaiting unrelated work before the call can consume the required user activation.
Handle errors in the calling UI; cancellation returns `null`.

Flutter registers the platform implementations automatically. Initialize Flutter
before using the plugin outside a widget callback. Screen sampling belongs on
the application's UI isolate.

## Result and error semantics

- `available` is synchronous. On Linux it identifies an implemented platform;
  it does not promise that the current desktop portal is running or compatible.
- `pick()` returns an integer in `0xFFRRGGBB` format, always opaque sRGB.
- Cancellation and overlapping requests return `null`. All clients in the same
  Dart isolate share the pending-request guard.
- Unsupported platforms throw `UnsupportedError`. Portal, native-channel,
  browser and malformed-response errors propagate.
- Linux closes unfinished portal requests and its private bus connection on
  every exit. Waiting for a user response is limited to five minutes.

On Windows, click to select a pixel; Escape, right-click, or switching to another window cancels. Screen layout changes abort the request. The returned value uses the desktop's legacy 8-bit RGB representation and does not expose HDR scene values.

## Scope

This is a system screen picker, separate from sampling an application's canvas
or decoding image files. It does not convert samples to a document's working
color space.

See [docs/platform_contract.md](docs/platform_contract.md) for platform behavior, request handling, color semantics, and integration requirements.

## Example and development

The [example application](example/README.md) includes a pick button, cancellation handling, and error feedback. Run it on a supported platform:

```sh
cd example
flutter pub get
flutter run -d linux
```

Use `windows`, `macos`, or `chrome` as the device on the corresponding host. See the [contributing guidelines](CONTRIBUTING.md) for automated checks and platform validation.

---

Built for **[Focale](https://focale-editor.app)**, an advanced local image editor. Discover what these packages make possible in a real creative workflow.
