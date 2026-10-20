import 'package:pickpick/src/method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Contract for platform implementations and test fakes.
abstract class PickpickPlatform extends PlatformInterface {
  /// Creates an implementation that can replace the default platform.
  PickpickPlatform() : super(token: _token);

  /// Verifies that replacement implementations extend this contract.
  static final Object _token = Object();

  /// Native default, replaced by Flutter's Linux and web registrants.
  static PickpickPlatform _instance = MethodChannelPickpick();

  /// The implementation used by all Pickpick clients.
  static PickpickPlatform get instance => _instance;

  /// Installs a verified platform implementation.
  static set instance(PickpickPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Whether this implementation can request a system picker.
  bool get available;

  /// Returns one opaque sRGB ARGB value, or `null` on cancellation.
  Future<int?> pick();
}
