import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pickpick/src/platform_interface.dart';
import 'package:pickpick/src/sampled_screen_color.dart';

/// Calls the macOS or Windows plugin and disables unsupported platforms.
final class MethodChannelPickpick extends PickpickPlatform {
  /// Creates a client for the plugin's method channel.
  MethodChannelPickpick();

  /// Native bridge registered independently of the host application.
  static const MethodChannel _channel = MethodChannel('app.focaleeditor/pickpick');

  @override
  bool get available => !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows);

  @override
  Future<int?> pick() async {
    if (!available) {
      throw UnsupportedError('Screen color sampling is unavailable on this platform.');
    }
    final List<double>? components = await _channel.invokeListMethod<double>('pickColor');
    return components == null ? null : SampledScreenColor.fromComponents(components);
  }
}
