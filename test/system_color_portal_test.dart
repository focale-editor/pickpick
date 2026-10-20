@TestOn('vm')
library;

import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick/src/linux.dart';

/// Exercises real D-Bus message ordering on an isolated in-process bus.
void main() {
  test('rejects an unexpected request path and closes the pending request', () async {
    final DBusServer server = DBusServer();
    final DBusAddress address = await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    final DBusClient service = DBusClient(address);
    addTearDown(() async {
      await service.close();
      await server.close();
    });
    final _Portal portal = _Portal(status: 0, wrongPath: true);
    await service.requestName('org.freedesktop.portal.Desktop');
    await service.registerObject(portal);

    await expectLater(PickpickLinux(connect: () => DBusClient(address)).pick(), throwsFormatException);
    expect(portal.request.closed, isTrue);
  }, skip: !Platform.isLinux);

  for (final int status in [0, 1, 2]) {
    test('handles an immediate portal response with status $status', () async {
      final DBusServer server = DBusServer();
      final DBusAddress address = await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
      final DBusClient service = DBusClient(address);
      addTearDown(() async {
        await service.close();
        await server.close();
      });
      await service.requestName('org.freedesktop.portal.Desktop');
      await service.registerObject(_Portal(status: status));

      final Future<int?> sample = PickpickLinux(connect: () => DBusClient(address)).pick();
      if (status == 0) {
        expect(await sample.timeout(const Duration(seconds: 5)), 0xffff8000);
      } else if (status == 1) {
        expect(await sample.timeout(const Duration(seconds: 5)), isNull);
      } else {
        await expectLater(sample.timeout(const Duration(seconds: 5)), throwsStateError);
      }
    }, skip: !Platform.isLinux);
  }
}

/// Returns a response before the method reply, as a fast real portal may do.
final class _Portal extends DBusObject {
  /// Portal completion status to send to the client.
  final int status;

  /// Whether to violate the request path contract.
  final bool wrongPath;

  /// Last request, retained to verify failure cleanup.
  late _Request request;

  /// Creates a private screenshot portal with a deterministic sRGB sample.
  _Portal({required this.status, this.wrongPath = false}) : super(DBusObjectPath('/org/freedesktop/portal/desktop'));

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async => DBusGetPropertyResponse(const DBusUint32(2));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.name != 'PickColor') {
      return DBusMethodErrorResponse.unknownMethod();
    }
    final String sender = methodCall.sender!.substring(1).replaceAll('.', '_');
    final String token = methodCall.values[1].asStringVariantDict()['handle_token']!.asString();
    request = _Request(path: DBusObjectPath('/org/freedesktop/portal/desktop/request/$sender/$token'));
    await client!.registerObject(request);
    await request.emitSignal('org.freedesktop.portal.Request', 'Response', [
      DBusUint32(status),
      DBusDict.stringVariant({
        'color': DBusStruct([const DBusDouble(1), const DBusDouble(0.5), const DBusDouble(0)]),
      }),
    ]);
    return DBusMethodSuccessResponse([if (wrongPath) DBusObjectPath('/wrong_request') else request.path]);
  }
}

/// Supplies a request path and a completion signal without touching the desktop.
final class _Request extends DBusObject {
  /// Whether the client explicitly closed this request.
  bool closed = false;

  /// Creates the portal request named by the caller's handle token.
  _Request({required DBusObjectPath path}) : super(path);

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.name == 'Close') {
      closed = true;
    }
    return DBusMethodSuccessResponse([]);
  }
}
