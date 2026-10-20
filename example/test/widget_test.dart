import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpick_example/main.dart';

void main() {
  testWidgets('selection updates the example and cancellation keeps the color', (tester) async {
    const MethodChannel channel = MethodChannel('app.focaleeditor/pickpick');
    List<double>? sample = [1.0, 0.5, 0.0];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => sample);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(home: PickerExample()));

    await tester.tap(find.text('Pick a screen color'));
    await tester.pumpAndSettle();
    expect(find.text('#FF8000'), findsOneWidget);
    sample = null;
    await tester.tap(find.text('Pick a screen color'));
    await tester.pumpAndSettle();
    expect(find.text('#FF8000'), findsOneWidget);
    expect(find.text('Cancelled — previous color kept.'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
