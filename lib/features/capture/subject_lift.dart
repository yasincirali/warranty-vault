import 'dart:collection';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A product photo ready for the shelf.
class LiftedPhoto {
  const LiftedPhoto({required this.png, required this.aspect, required this.cutout});
  final Uint8List png;

  /// Width / height.
  final double aspect;

  /// True = background removed (transparent PNG).
  final bool cutout;
}

/// Both versions of one photo, so the "Original" toggle on the add screen
/// switches instantly instead of re-running the lift.
class LiftResult {
  const LiftResult({required this.original, this.cutout});
  final LiftedPhoto original;

  /// Null when the lift could not find a clear subject; the original is
  /// used and the toggle is hidden.
  final LiftedPhoto? cutout;
}

/// Longest side kept on the phone. A shelf shows products at ≤ 120 pt, the
/// detail at ≤ 240 pt; 900 px covers that at 3× with room to spare and keeps
/// a cabinet of 200 things under ~40 MB.
const _maxSide = 900;

/// Lifts the product off its background, like "Lift subject" in iOS Photos.
///
/// v1 is a plain flood fill from the photo's edges: products photographed on
/// a table, bed or wall have a fairly even background touching the edges.
/// A pixel joins the background when it is close to the neighbour it was
/// reached from (soft gradients and shadows) AND not far from the edges'
/// average colour (so the fill cannot leak through a low-contrast product
/// edge into the product itself). Thresholds are the ones tuned in the HTML
/// prototype (Tur 5): 30 and 150 in RGB distance.
///
/// TODO(lift): VisionKit (iOS 17 `ImageAnalysisInteraction` subject lifting)
/// and ML Kit Subject Segmentation (Android) give real segmentation; this
/// stays as the fallback for older devices.
///
/// Pure and synchronous: run it with `Isolate.run`.
LiftResult liftSubject(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('not an image');
  var src = img.bakeOrientation(decoded);
  if (src.width > _maxSide || src.height > _maxSide) {
    src = src.width >= src.height
        ? img.copyResize(src, width: _maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(src, height: _maxSide, interpolation: img.Interpolation.average);
  }
  final original = LiftedPhoto(png: img.encodePng(src, level: 6), aspect: src.width / src.height, cutout: false);
  return LiftResult(original: original, cutout: _cut(src));
}

LiftedPhoto? _cut(img.Image src) {
  final w = src.width, h = src.height;
  if (w < 16 || h < 16) return null;

  final r = Int32List(w * h), g = Int32List(w * h), b = Int32List(w * h);
  for (final p in src) {
    final i = p.y * w + p.x;
    r[i] = p.r.toInt();
    g[i] = p.g.toInt();
    b[i] = p.b.toInt();
  }

  var mr = 0, mg = 0, mb = 0, n = 0;
  void edge(int i) {
    mr += r[i];
    mg += g[i];
    mb += b[i];
    n++;
  }

  for (var x = 0; x < w; x++) {
    edge(x);
    edge((h - 1) * w + x);
  }
  for (var y = 1; y < h - 1; y++) {
    edge(y * w);
    edge(y * w + w - 1);
  }
  mr ~/= n;
  mg ~/= n;
  mb ~/= n;

  int d2(int i, int j) {
    final dr = r[i] - r[j], dg = g[i] - g[j], db = b[i] - b[j];
    return dr * dr + dg * dg + db * db;
  }

  int dMean(int i) {
    final dr = r[i] - mr, dg = g[i] - mg, db = b[i] - mb;
    return dr * dr + dg * dg + db * db;
  }

  const near = 30 * 30, far = 150 * 150;
  final bg = Uint8List(w * h);
  final queue = Queue<int>();
  void seed(int i) {
    if (bg[i] == 0 && dMean(i) < far) {
      bg[i] = 1;
      queue.add(i);
    }
  }

  for (var x = 0; x < w; x++) {
    seed(x);
    seed((h - 1) * w + x);
  }
  for (var y = 0; y < h; y++) {
    seed(y * w);
    seed(y * w + w - 1);
  }
  var removed = queue.length;
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % w, y = i ~/ w;
    for (final j in [if (x > 0) i - 1, if (x < w - 1) i + 1, if (y > 0) i - w, if (y < h - 1) i + w]) {
      if (bg[j] == 0 && d2(i, j) < near && dMean(j) < far) {
        bg[j] = 1;
        removed++;
        queue.add(j);
      }
    }
  }

  // Too little removed: no clear background. Too much: the product was
  // eaten. Either way the original photo is the honest result.
  final share = removed / (w * h);
  if (share < .05 || share > .92) return null;

  var x0 = w, y0 = h, x1 = -1, y1 = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bg[y * w + x] == 0) {
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
      }
    }
  }
  if (x1 < x0 || y1 < y0) return null;

  const pad = 4;
  x0 = (x0 - pad).clamp(0, w - 1);
  y0 = (y0 - pad).clamp(0, h - 1);
  x1 = (x1 + pad).clamp(0, w - 1);
  y1 = (y1 + pad).clamp(0, h - 1);
  final cw = x1 - x0 + 1, ch = y1 - y0 + 1;

  final out = img.Image(width: cw, height: ch, numChannels: 4);
  for (var y = 0; y < ch; y++) {
    for (var x = 0; x < cw; x++) {
      final sx = x + x0, sy = y + y0, i = sy * w + sx;
      int a;
      if (bg[i] == 1) {
        a = 0;
      } else {
        // One-pixel feather: a hard cut-out edge looks pasted on.
        final touches =
            (sx > 0 && bg[i - 1] == 1) ||
            (sx < w - 1 && bg[i + 1] == 1) ||
            (sy > 0 && bg[i - w] == 1) ||
            (sy < h - 1 && bg[i + w] == 1);
        a = touches ? 150 : 255;
      }
      out.setPixelRgba(x, y, r[i], g[i], b[i], a);
    }
  }
  return LiftedPhoto(png: img.encodePng(out, level: 6), aspect: cw / ch, cutout: true);
}
