# Pickpick example

From this directory:

```sh
flutter pub get
flutter run -d linux
# Or: flutter run -d windows
# Or: flutter run -d macos
# Or: flutter run -d chrome
```

Choose **Pick a screen color**, select a pixel, then repeat and cancel with
Escape. The previous color should remain after cancellation. A missing Linux
portal or rejected browser request is shown as an error. Unsupported platforms
show a disabled button.

The macOS runner uses Flutter's standard generated plugin registration. No
application-specific method channel or screen recording permission is needed.
