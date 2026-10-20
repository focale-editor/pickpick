import Cocoa
import FlutterMacOS

/// Presents the system color sampler without capturing screen images.
public final class PickpickPlugin: NSObject, FlutterPlugin {
  /// Retains the sampler until its completion callback runs.
  private var sampler: NSColorSampler?

  /// Registers the plugin with the host engine's messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "app.focaleeditor/pickpick",
      binaryMessenger: registrar.messenger
    )
    registrar.addMethodCallDelegate(PickpickPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickColor" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard sampler == nil else {
      result(nil)
      return
    }
    let activeSampler = NSColorSampler()
    sampler = activeSampler
    activeSampler.show { [weak self] color in
      self?.sampler = nil
      guard let color = color else {
        result(nil)
        return
      }
      guard let converted = color.usingColorSpace(.sRGB) else {
        result(FlutterError(
          code: "color_conversion",
          message: "Cannot convert the sampled color to sRGB.",
          details: nil
        ))
        return
      }
      result([
        Double(converted.redComponent),
        Double(converted.greenComponent),
        Double(converted.blueComponent)
      ])
    }
  }
}
