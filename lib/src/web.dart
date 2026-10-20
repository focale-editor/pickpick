import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pickpick/src/platform_interface.dart';
import 'package:pickpick/src/sampled_screen_color.dart';
import 'package:web/web.dart' as web;

/// Delegates desktop colour consent and sampling to the browser EyeDropper API.
final class PickpickWeb extends PickpickPlatform {
  /// Creates a browser picker without opening any system interface.
  PickpickWeb();

  /// Registers the browser implementation with Flutter.
  static void registerWith(Registrar registrar) {
    PickpickPlatform.instance = PickpickWeb();
  }

  /// Whether the current secure browser context exposes the native picker.
  @override
  bool get available => web.window.isSecureContext && _eyeDropperConstructor != null;

  /// Opens the picker directly from a user activation; Escape leaves colour intact.
  @override
  Future<int?> pick() async {
    if (!available) {
      throw UnsupportedError('The browser does not provide an EyeDropper.');
    }
    final JSObject result;
    try {
      result = await _EyeDropper().open().toDart;
    } on Object catch (error) {
      final JSAny exception = error as JSAny;
      if (exception.isA<web.DOMException>() && (exception as web.DOMException).name == 'AbortError') {
        return null;
      }
      rethrow;
    }
    return SampledScreenColor.fromHex(result.getProperty<JSString>('sRGBHex'.toJS).toDart);
  }
}

/// Minimal interop surface for the browser-owned screen picker.
@JS('EyeDropper')
extension type _EyeDropper._(JSObject _) implements JSObject {
  /// Creates a picker without reading any screen pixels.
  external factory _EyeDropper();

  /// Requests one user-approved sRGB sample.
  external JSPromise<JSObject> open();
}

/// Browser constructor, absent in browsers without the EyeDropper API.
@JS('EyeDropper')
external JSFunction? get _eyeDropperConstructor;
