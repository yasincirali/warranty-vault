import CoreImage
import Flutter
import ImageIO
import UIKit
import Vision

/// Product photo → the product without its background, with the model behind
/// "Lift subject" in Photos (Vision, iOS 17+). Answers a transparent PNG
/// cropped to the product, or a FlutterError whose code says why not
/// (`ios_old`, `decode`, `no_subject`, `vision`, `render`). On any error the
/// Dart side falls back to its flood fill (`subject_lift.dart`); the code is
/// shown small under the photo so a "not lifted" report from TestFlight says
/// which step failed (yasin, 18 Oct: "hala algılayamıyor").
enum SubjectLift {
  static let channelName = "warranty_vault/subject_lift"

  /// Vision works on the photo the user sees; 1800 px matches the picker's
  /// limit and keeps the request well under a second.
  private static let maxSide = 1800

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let bytes = call.arguments as? FlutterStandardTypedData else {
        result(FlutterMethodNotImplemented)
        return
      }
      if call.method == "classify" {
        DispatchQueue.global(qos: .userInitiated).async {
          let labels = classify(bytes.data)
          DispatchQueue.main.async { result(labels) }
        }
        return
      }
      guard call.method == "lift" else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Segmentation takes a few hundred ms; never on the main thread.
      DispatchQueue.global(qos: .userInitiated).async {
        let answer: Any
        switch lift(bytes.data) {
        case .success(let png): answer = FlutterStandardTypedData(bytes: png)
        case .failure(let why): answer = FlutterError(code: why.rawValue, message: nil, details: nil)
        }
        DispatchQueue.main.async { result(answer) }
      }
    }
  }

  enum Failure: String, Error { case iosOld = "ios_old", decode, noSubject = "no_subject", vision, render }

  static func lift(_ data: Data) -> Result<Data, Failure> {
    guard #available(iOS 17.0, *) else { return .failure(.iosOld) }
    guard let upright = uprightCGImage(data) else { return .failure(.decode) }
    let handler = VNImageRequestHandler(cgImage: upright, options: [:])
    let request = VNGenerateForegroundInstanceMaskRequest()
    let buffer: CVPixelBuffer
    do {
      try handler.perform([request])
      guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
        return .failure(.noSubject)
      }
      // All instances: a pair of earbuds is two "subjects" but one product.
      buffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: true
      )
    } catch {
      return .failure(.vision)
    }
    // Explicit 8-bit sRGB: the masked buffer may come back in the photo's
    // wide (P3 / extended) space, which the Dart PNG decoder reads wrongly.
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB) else { return .failure(.render) }
    let masked = CIImage(cvPixelBuffer: buffer)
    let context = CIContext(options: [.workingColorSpace: srgb, .outputColorSpace: srgb])
    guard let cg = context.createCGImage(masked, from: masked.extent, format: .RGBA8, colorSpace: srgb),
          let png = UIImage(cgImage: cg).pngData()
    else { return .failure(.render) }
    return .success(png)
  }

  /// What the photo shows, as Vision's own labels ("laptop", "headphones",
  /// "television"…) with their confidence, strongest first. On-device and
  /// free (iOS 13+); the Dart side maps labels to the seven kinds
  /// (`category_guess.dart`). Empty on any failure: the kind is then left
  /// to the name and the user, never guessed.
  static func classify(_ data: Data) -> [[Any]] {
    guard let upright = uprightCGImage(data, limit: 600) else { return [] }
    let handler = VNImageRequestHandler(cgImage: upright, options: [:])
    let request = VNClassifyImageRequest()
    do {
      try handler.perform([request])
    } catch {
      return []
    }
    return (request.results ?? [])
      .filter { $0.confidence >= 0.1 }
      .sorted { $0.confidence > $1.confidence }
      .prefix(15)
      .map { [$0.identifier, Double($0.confidence)] }
  }

  /// The photo the right way up and at most [limit] px, straight from
  /// ImageIO: it reads HEIC and applies the EXIF orientation itself (a
  /// portrait camera photo is stored sideways with a flag), with no
  /// UIGraphics redraw that could hand Vision an extended-range bitmap.
  private static func uprightCGImage(_ data: Data, limit: Int = SubjectLift.maxSide) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: limit,
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }
}
