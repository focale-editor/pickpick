import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick/src/sampled_screen_color.dart';

void main() {
  test('portal sRGB components become an opaque colour', () {
    check(SampledScreenColor.fromComponents([1, 0.5, 0])).equals(0xffff8000);
    check(SampledScreenColor.fromHex('#ff8000')).equals(0xffff8000);
  });

  test('malformed native samples are rejected instead of silently clamped', () {
    for (final List<double> values in [
      <double>[],
      [1, 0],
      [1, 0, 0, 1],
      [-1, 0, 0],
      [1.1, 0, 0],
      [double.nan, 0, 0],
      [double.infinity, 0, 0],
    ]) {
      expect(() => SampledScreenColor.fromComponents(values), throwsFormatException);
    }
    for (final String value in ['ff8000', '#fff', '#ff800000', '#zz0000']) {
      expect(() => SampledScreenColor.fromHex(value), throwsFormatException);
    }
  });
}
