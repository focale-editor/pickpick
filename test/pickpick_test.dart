import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick/pickpick.dart';
import 'package:pickpick/src/platform_interface.dart';

void main() {
  late PickpickPlatform original;
  late _FakePicker backend;
  const Pickpick picker = Pickpick();

  setUp(() {
    original = PickpickPlatform.instance;
    backend = _FakePicker();
    PickpickPlatform.instance = backend;
  });
  tearDown(() => PickpickPlatform.instance = original);

  test('starts the platform request synchronously and returns its color', () async {
    final Future<int?> pending = picker.pick();
    check(backend.calls).equals(1);
    backend.response.complete(0xff123456);
    check(await pending).equals(0xff123456);
  });

  test('cancellation returns null', () async {
    backend.response.complete(null);
    check(await picker.pick()).isNull();
  });

  test('clients share the pending request guard and can pick again', () async {
    final Future<int?> pending = picker.pick();
    check(await const Pickpick().pick()).isNull();
    check(backend.calls).equals(1);
    backend.response.complete(0xff123456);
    await pending;
    backend.response = Completer()..complete(0xffabcdef);
    check(await picker.pick()).equals(0xffabcdef);
    check(backend.calls).equals(2);
  });

  test('a failed request releases the pending request guard', () async {
    final Future<int?> pending = picker.pick();
    final Future<void> failure = expectLater(pending, throwsStateError);
    backend.response.completeError(StateError('Portal failed'));
    await failure;
    backend.response = Completer()..complete(0xffabcdef);
    check(await picker.pick()).equals(0xffabcdef);
  });

  test('unsupported platforms fail without calling the backend', () async {
    backend.available = false;
    check(picker.available).isFalse();
    await expectLater(picker.pick(), throwsUnsupportedError);
    check(backend.calls).equals(0);
  });
}

/// Holds a request open without accessing any system interface.
final class _FakePicker extends PickpickPlatform {
  /// Creates a controllable backend.
  _FakePicker();

  @override
  bool available = true;

  /// Number of requests actually opened.
  int calls = 0;

  /// Result supplied by the current test.
  Completer<int?> response = Completer();

  @override
  Future<int?> pick() {
    calls++;
    return response.future;
  }
}
