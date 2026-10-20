@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick/pickpick.dart';
import 'package:pickpick/src/platform_interface.dart';
import 'package:pickpick/src/web.dart';
import 'package:web/web.dart' as web;

void main() {
  late JSAny? originalConstructor;
  late PickpickPlatform originalPlatform;
  const Pickpick picker = Pickpick();

  setUp(() {
    originalConstructor = web.window.getProperty<JSAny?>('EyeDropper'.toJS);
    originalPlatform = PickpickPlatform.instance;
    PickpickPlatform.instance = PickpickWeb();
    web.window.setProperty('pickpickOpens'.toJS, 0.toJS);
  });
  tearDown(() {
    web.window.setProperty('EyeDropper'.toJS, originalConstructor);
    PickpickPlatform.instance = originalPlatform;
  });

  test('opens before yielding user activation and converts the browser result', () async {
    _installPicker("return Promise.resolve({sRGBHex: '#12AB34'});");
    final Future<int?> pending = picker.pick();
    check(web.window.getProperty<JSNumber>('pickpickOpens'.toJS).toDartInt).equals(1);
    check(await pending).equals(0xff12ab34);
  });

  test('AbortError is cancellation and allows another request', () async {
    _installPicker("return Promise.reject(new DOMException('Cancelled', 'AbortError'));");
    check(await picker.pick()).isNull();
    _installPicker("return Promise.resolve({sRGBHex: '#112233'});");
    check(await picker.pick()).equals(0xff112233);
  });

  test('other browser errors propagate and release the pending guard', () async {
    _installPicker("return Promise.reject(new DOMException('Denied', 'NotAllowedError'));");
    await expectLater(picker.pick(), throwsA(anything));
    _installPicker("return Promise.resolve({sRGBHex: '#112233'});");
    check(await picker.pick()).equals(0xff112233);
  });

  test('malformed browser colors are rejected', () async {
    _installPicker("return Promise.resolve({sRGBHex: '#123'});");
    await expectLater(picker.pick(), throwsFormatException);
  });

  test('absence of EyeDropper disables the API', () async {
    web.window.setProperty('EyeDropper'.toJS, null);
    check(picker.available).isFalse();
    await expectLater(picker.pick(), throwsUnsupportedError);
  });
}

/// Installs a browser-owned promise boundary without opening a real picker.
void _installPicker(String body) {
  final JSFunction constructor = _createFunction('return class { open() { globalThis.pickpickOpens++; $body } };'.toJS).callAsFunction() as JSFunction;
  web.window.setProperty('EyeDropper'.toJS, constructor);
}

/// Creates controlled JavaScript fixtures for browser interop tests.
@JS('Function')
external JSFunction _createFunction(JSString body);
