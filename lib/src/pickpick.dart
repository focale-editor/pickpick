import 'package:pickpick/src/platform_interface.dart';

/// Selects one screen color through a native desktop or browser picker.
final class Pickpick {
  /// Creates a client for the current platform's screen picker.
  const Pickpick();

  /// Whether a sample is already pending in this Dart isolate.
  static bool _busy = false;

  /// Whether this platform has an implemented screen picker.
  ///
  /// Linux also requires a running desktop portal with Screenshot version 2
  /// or later. This synchronous getter does not probe that service; [pick]
  /// reports missing or incompatible portals.
  ///
  /// On the web this checks the current secure context and EyeDropper API.
  bool get available => PickpickPlatform.instance.available;

  /// Picks an opaque sRGB color encoded as `0xFFRRGGBB`.
  ///
  /// Returns `null` on cancellation or while another request is active.
  /// Throws [UnsupportedError] on unsupported platforms. Platform, portal and
  /// malformed-response errors propagate to the caller.
  ///
  /// Call directly from a user gesture, without awaiting another operation
  /// first: browsers require transient user activation to open their picker.
  Future<int?> pick() async {
    if (_busy) {
      return null;
    }
    final PickpickPlatform platform = PickpickPlatform.instance;
    if (!platform.available) {
      throw UnsupportedError('Screen color sampling is unavailable on this platform.');
    }
    _busy = true;
    try {
      return await platform.pick();
    } finally {
      _busy = false;
    }
  }
}
