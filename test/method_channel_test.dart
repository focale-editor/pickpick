@TestOn('vm')
library;

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick/src/method_channel.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('app.focaleeditor/pickpick');
  final MethodChannelPickpick picker = MethodChannelPickpick();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final TargetPlatform platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    test('$platform converts native sRGB components through the package channel', () async {
      debugDefaultTargetPlatformOverride = platform;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        check(call.method).equals('pickColor');
        return [1.0, 0.5, 0.0];
      });
      check(picker.available).isTrue();
      check(await picker.pick()).equals(0xffff8000);
    });

    test('$platform preserves cancellation', () async {
      debugDefaultTargetPlatformOverride = platform;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => null);
      check(await picker.pick()).isNull();
    });

    test('$platform propagates failures and rejects malformed colors', () async {
      debugDefaultTargetPlatformOverride = platform;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: 'sample_failed'));
      await expectLater(picker.pick(), throwsA(isA<PlatformException>()));
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => [1.5, 0.0, 0.0]);
      await expectLater(picker.pick(), throwsFormatException);
    });
  }

  test('unsupported native platforms do not open a channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    check(picker.available).isFalse();
    await expectLater(picker.pick(), throwsUnsupportedError);
  });
}
