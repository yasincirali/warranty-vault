import CoreImage
import Flutter
import UIKit
import Vision

/// Product photo → the product without its background, with the model behind
/// "Lift subject" in Photos (Vision, iOS 17+). Answers a transparent PNG
/// cropped to the product, or nil: older iOS, the simulator (no Neural
/// Engine), or no subject found. On nil the Dart side falls back to its
/// flood fill (`subject_lift.dart`), so nothing here may throw at Dart.
enum SubjectLift {
  static let channelName = "warranty_vault/subject_lift"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "lift", let bytes = call.arguments as? FlutterStandardTypedData else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Segmentation takes a few hundred ms; never on the main thread.
      DispatchQueue.global(qos: .userInitiated).async {
        let png = lift(bytes.data)
        DispatchQueue.main.async {
          result(png.map { FlutterStandardTypedData(bytes: $0) })
        }
      }
    }
  }

  static func lift(_ data: Data) -> Data? {
    guard #available(iOS 17.0, *) else { return nil }
    guard let image = UIImage(data: data), let upright = uprightCGImage(image) else { return nil }
    let handler = VNImageRequestHandler(cgImage: upright, options: [:])
    let request = VNGenerateForegroundInstanceMaskRequest()
    do {
      try handler.perform([request])
      guard let observation = request.results?.first, !observation.allInstances.isEmpty else { return nil }
      // All instances: a pair of earbuds is two "subjects" but one product.
      let buffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: true
      )
      let masked = CIImage(cvPixelBuffer: buffer)
      guard let cg = CIContext().createCGImage(masked, from: masked.extent) else { return nil }
      return UIImage(cgImage: cg).pngData()
    } catch {
      return nil
    }
  }

  /// The photo drawn the right way up: Vision reads raw pixels, and a
  /// portrait camera photo is stored sideways with an orientation flag.
  private static func uprightCGImage(_ image: UIImage) -> CGImage? {
    if image.imageOrientation == .up, let cg = image.cgImage { return cg }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let drawn = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
    return drawn.cgImage
  }
}
