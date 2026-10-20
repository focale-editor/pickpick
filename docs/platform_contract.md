# Pickpick platform contract

This document describes the screen-picking behavior exposed by Pickpick, its platform implementations, and the boundaries of the returned color values.

## Public API

Create a `const Pickpick()` client and use its two members:

| Member | Result | Meaning |
| --- | --- | --- |
| `available` | `bool` | Whether the current implementation can request a picker; Linux does not probe the portal service here |
| `pick()` | `Future<int?>` | An opaque sRGB color in `0xFFRRGGBB` format, or `null` on cancellation or an overlapping request |

All clients in the same Dart isolate share the pending-request guard. An overlapping call returns `null` immediately without opening another picker. Completion, cancellation, and errors release that guard so a later call can try again.

Flutter registers the implementations automatically. Initialize Flutter before using the plugin outside a widget callback, and perform screen sampling on the application's UI isolate.

## Color representation

Successful samples are opaque sRGB values with an alpha byte of `0xFF`. Pass the integer directly to Flutter's `Color` constructor.

Native and Linux portal responses contain three normalized components. Pickpick requires exactly three finite values in the range 0–1, then rounds each component to an 8-bit value. Browser responses must contain a six-digit `#RRGGBB` string. Malformed color responses throw `FormatException`.

Pickpick does not convert samples to a document's working color space. It does not sample an application's canvas or decode image files, and the host application receives one color rather than a desktop image.

## Linux desktop portal

The Linux implementation calls XDG Desktop Portal `Screenshot.PickColor` over the session D-Bus. It works with Wayland or X11 when the desktop portal backend implements Screenshot version 2 or later.

`available` identifies Linux as an implemented platform; it does not guarantee that a portal service is running or compatible. `pick()` checks the portal version and propagates service or compatibility errors.

Each request owns a private bus connection. The implementation subscribes to the request response before launching the picker, checks the returned request path and response structure, and accepts responses from the portal owner. A cancellation response returns `null`; an unsuccessful response or malformed color produces an error.

Waiting for user selection is limited to five minutes. Unfinished portal requests are closed on exit, and the signal subscription and private bus connection are released on every path.

## macOS sampler

The macOS implementation uses `NSColorSampler` through the plugin's method channel. It requires macOS 12 or later and supports both CocoaPods and Swift Package Manager integration.

The example uses Flutter's standard generated plugin registration. No application-specific method channel or screen recording permission is needed. Cancellation returns `null`; native-channel errors propagate to the caller.

## Windows picker

Windows uses a small Win32 implementation rather than an OS-provided eyedropper control. A nearly transparent input window covers the virtual desktop and shows a crosshair.

- Click to select a pixel.
- Escape, right-click, or switching to another window cancels.
- Screen layout changes abort the request.

The input window becomes fully transparent before `GetPixel` reads the chosen pixel, then closes. This keeps focus changes from affecting the sample. No desktop image is captured or retained.

The Windows path requires Windows 10 or later and an interactive desktop. It returns the desktop's legacy 8-bit RGB representation; it does not expose HDR scene values or perform document-profile conversion. Protected content and the secure desktop are outside its supported sampling surface.

See Microsoft's [GetPixel documentation](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getpixel) for the underlying pixel-reading API.

## Browser picker

The web implementation delegates selection to the browser's `EyeDropper` API. `available` checks both the secure context and the presence of that API; browser support is required.

Invoke `pick()` directly from a button or another user gesture. Awaiting unrelated work first can consume the transient user activation required to open the picker.

The browser's `AbortError` is treated as cancellation and returns `null`. Other browser errors propagate. Pickpick validates the returned `sRGBHex` value before converting it to an opaque ARGB integer.

## Errors and unsupported platforms

Android and iOS have no implementation: `available` is `false` and `pick()` throws `UnsupportedError`. The same applies when the browser lacks the required API or secure context. An incompatible Linux portal can also throw `UnsupportedError` after `available` has returned `true`.

Portal, native-channel, browser, timeout, and malformed-response errors are not converted to cancellation. Handle them in the calling UI so users can distinguish a cancelled selection from a failed request. A `null` result should normally leave the previous color unchanged.

## Validation boundaries

The tests exercise request coordination, native-channel responses, color validation, an isolated in-process D-Bus portal, and a fake browser `EyeDropper`. They do not replace manual selection and cancellation on a real system interface.

See the [example application](../example/README.md) for a manual workflow and the [contributing guidelines](../CONTRIBUTING.md) for platform-specific checks.
