/// Validates the sRGB result of an operating-system screen colour picker.
abstract final class SampledScreenColor {
  /// Converts normalized portal components to an opaque ARGB colour.
  static int fromComponents(List<double> components) {
    if (components.length != 3 || components.any((value) => !value.isFinite || value < 0 || value > 1)) {
      throw const FormatException('The screen picker returned invalid sRGB components.');
    }
    return 0xff000000 | (components[0] * 255).round() << 16 | (components[1] * 255).round() << 8 | (components[2] * 255).round();
  }

  /// Decodes the browser EyeDropper API's explicit six-digit sRGB value.
  static int fromHex(String value) {
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      throw const FormatException('The screen picker returned an invalid sRGB colour.');
    }
    return 0xff000000 | int.parse(value.substring(1), radix: 16);
  }
}
