import 'package:flutter/material.dart';
import 'package:pickpick/pickpick.dart';

/// Runs a small manual selection and cancellation demo.
void main() => runApp(const MaterialApp(home: PickerExample()));

/// Shows the last selected color and any platform error.
class PickerExample extends StatefulWidget {
  /// Creates the example screen.
  const PickerExample({super.key});

  @override
  State<PickerExample> createState() => _PickerExampleState();
}

/// Keeps the previous color intact when the user cancels.
class _PickerExampleState extends State<PickerExample> {
  /// Client shared by all button presses.
  static const Pickpick _picker = Pickpick();

  /// Current opaque sRGB value.
  int _color = 0xff007cf9;

  /// Whether a system request is pending.
  bool _picking = false;

  /// Last request's feedback.
  String? _message;

  /// Starts directly in the gesture callback to preserve browser activation.
  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _message = null;
    });
    try {
      final int? color = await _picker.pick();
      if (!mounted) {
        return;
      }
      setState(() {
        if (color != null) {
          _color = color;
        }
        _message = color == null ? 'Cancelled — previous color kept.' : 'Color selected.';
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _message = 'Selection failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pickpick')),
    body: Center(
      child: Padding(
        padding: const .all(24),
        child: Column(
          mainAxisSize: .min,
          spacing: 24,
          children: [
            SizedBox(width: 160, height: 160, child: ColoredBox(color: Color(_color))),
            Text('#${(_color & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}'),
            FilledButton(
              onPressed: _picker.available && !_picking ? _pick : null,
              child: Text(_picking ? 'Choose a pixel or press Escape…' : 'Pick a screen color'),
            ),
            if (!_picker.available) const Text('No system picker is available on this platform.'),
            if (_message case final String message) Text(message),
          ],
        ),
      ),
    ),
  );
}
