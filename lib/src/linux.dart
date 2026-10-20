import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:pickpick/src/platform_interface.dart';
import 'package:pickpick/src/sampled_screen_color.dart';
import 'package:uuid/uuid.dart';

/// Picks a color through the desktop portal on Wayland and X11.
final class PickpickLinux extends PickpickPlatform {
  /// Opens a private bus connection for each request.
  final DBusClient Function() _connect;

  /// Creates a portal implementation, optionally using a private test bus.
  ///
  /// Each connection returned by [connect] is owned and closed by the picker.
  PickpickLinux({DBusClient Function()? connect}) : _connect = connect ?? DBusClient.session;

  /// Registers the Dart implementation with Flutter on Linux.
  static void registerWith() {
    PickpickPlatform.instance = PickpickLinux();
  }

  @override
  bool get available => true;

  @override
  Future<int?> pick() async {
    final DBusClient client = _connect();
    StreamSubscription<DBusSignal>? subscription;
    DBusRemoteObject? request;
    bool finished = false;
    try {
      const String service = 'org.freedesktop.portal.Desktop';
      const String screenshot = 'org.freedesktop.portal.Screenshot';
      final DBusRemoteObject portal = DBusRemoteObject(client, name: service, path: DBusObjectPath('/org/freedesktop/portal/desktop'));
      final DBusValue version = await portal.getProperty(screenshot, 'version').timeout(const Duration(seconds: 10));
      if (version.asUint32() < 2) {
        throw UnsupportedError('The desktop portal does not support PickColor.');
      }
      final String? owner = await client.getNameOwner(service);
      final String token = 'pickpick_${const Uuid().v4().replaceAll('-', '_')}';
      final String sender = client.uniqueName.substring(1).replaceAll('.', '_');
      final DBusObjectPath path = DBusObjectPath('/org/freedesktop/portal/desktop/request/$sender/$token');
      request = DBusRemoteObject(client, name: service, path: path);
      // Subscribe before launching the picker: an immediate cancellation can
      // arrive before PickColor's method reply. Errors are stored as values so
      // they cannot become unhandled while that reply is still in flight.
      final Completer<({DBusSignal? signal, Object? error})> response = Completer();
      subscription = DBusSignalStream(client, path: path, interface: 'org.freedesktop.portal.Request', name: 'Response').listen(
        (signal) {
          if (!response.isCompleted && signal.sender == owner) {
            response.complete((signal: signal, error: null));
          }
        },
        onError: (Object error) {
          if (!response.isCompleted) {
            response.complete((signal: null, error: error));
          }
        },
      );
      final DBusMethodSuccessResponse result = await portal
          .callMethod(
            screenshot,
            'PickColor',
            [
              const DBusString(''),
              DBusDict.stringVariant({'handle_token': DBusString(token)}),
            ],
            replySignature: DBusSignature('o'),
          )
          .timeout(const Duration(seconds: 15));
      if (result.returnValues.single.asObjectPath() != path) {
        throw const FormatException('The desktop portal returned an unexpected request path.');
      }
      final ({DBusSignal? signal, Object? error}) received = await response.future.timeout(const Duration(minutes: 5));
      if (received.error case final Object error) {
        throw StateError('Screen picker signal failed: $error');
      }
      final List<DBusValue> values = received.signal!.values;
      if (received.signal!.signature != DBusSignature('ua{sv}')) {
        throw const FormatException('The desktop portal returned an invalid response.');
      }
      finished = true;
      final int status = values.first.asUint32();
      if (status == 1) {
        return null;
      }
      if (status != 0) {
        throw StateError('The desktop portal could not sample a colour.');
      }
      final DBusValue? color = values[1].asStringVariantDict()['color'];
      if (color is! DBusStruct || color.signature != DBusSignature('(ddd)')) {
        throw const FormatException('The desktop portal did not return a colour.');
      }
      return SampledScreenColor.fromComponents(color.children.map((value) => value.asDouble()).toList());
    } finally {
      if (!finished && request != null) {
        try {
          await request.callMethod('org.freedesktop.portal.Request', 'Close', [], replySignature: DBusSignature('')).timeout(const Duration(seconds: 2));
        } on Object {
          // Closing the private bus connection also cancels a lost request.
        }
      }
      try {
        await subscription?.cancel();
      } finally {
        await client.close();
      }
    }
  }
}
