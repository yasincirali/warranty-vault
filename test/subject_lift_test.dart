import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:warranty_vault/features/capture/subject_lift.dart';

Uint8List _photo({required int w, required int h, required void Function(img.Image) paint}) {
  final im = img.Image(width: w, height: h);
  paint(im);
  return img.encodeJpg(im, quality: 95);
}

void main() {
  test('a product on an even background is lifted and cropped to itself', () {
    final bytes = _photo(
      w: 400,
      h: 300,
      paint: (im) {
        img.fill(im, color: img.ColorRgb8(236, 232, 224)); // table top
        img.fillRect(im, x1: 150, y1: 60, x2: 250, y2: 260, color: img.ColorRgb8(30, 60, 160)); // mug
      },
    );
    final r = liftSubject(bytes);
    expect(r.cutout, isNotNull);
    // 100 x 200 product + 4 px padding on each side.
    expect(r.cutout!.aspect, closeTo(108 / 208, .03));
    final out = img.decodePng(r.cutout!.png)!;
    expect(out.getPixel(0, 0).a, 0, reason: 'corner is background');
    expect(out.getPixel(out.width ~/ 2, out.height ~/ 2).a, 255, reason: 'centre is product');
    expect(r.original.cutout, isFalse);
    expect(r.original.aspect, closeTo(4 / 3, .01));
  });

  test('a busy photo with no clear background keeps the original', () {
    final bytes = _photo(
      w: 120,
      h: 120,
      paint: (im) {
        for (final p in im) {
          final v = (p.x * 37 + p.y * 91) % 255;
          p.setRgb(v, 255 - v, (v * 3) % 255);
        }
      },
    );
    final r = liftSubject(bytes);
    expect(r.cutout, isNull);
  });

  test('large photos are scaled down to 900 px', () {
    final bytes = _photo(w: 2000, h: 1000, paint: (im) => img.fill(im, color: img.ColorRgb8(200, 200, 200)));
    final out = img.decodePng(liftSubject(bytes).original.png)!;
    expect(out.width, 900);
    expect(out.height, 450);
  });

  test('not an image is an error, not a crash', () {
    expect(() => liftSubject(Uint8List.fromList([1, 2, 3])), throwsFormatException);
  });
}
