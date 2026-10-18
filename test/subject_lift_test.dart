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

  group('formats the Dart decoder cannot read (HEIC)', () {
    // The first bytes of an iPhone HEIC file: an ISO-BMFF "ftypheic" box.
    final heic = Uint8List.fromList([0, 0, 0, 24, ...'ftypheic'.codeUnits, 0, 0, 0, 0, ...'mif1heic'.codeUnits]);

    test('are recognised as such, cheaply', () {
      expect(dartCanDecode(heic), isFalse);
      expect(dartCanDecode(_photo(w: 8, h: 8, paint: (_) {})), isTrue);
    });

    test('are lifted from the pixels the phone decoded', () {
      final im = img.Image(width: 400, height: 300, numChannels: 4);
      img.fill(im, color: img.ColorRgba8(236, 232, 224, 255));
      img.fillRect(im, x1: 150, y1: 60, x2: 250, y2: 260, color: img.ColorRgba8(30, 60, 160, 255));
      final raw = RawPhoto(width: 400, height: 300, rgba: im.getBytes(order: img.ChannelOrder.rgba));
      final r = liftSubject(heic, raw: raw);
      expect(r.original.aspect, closeTo(4 / 3, .01));
      expect(r.cutout, isNotNull);
      expect(r.cutout!.aspect, closeTo(108 / 208, .03));
    });

    test('without decoded pixels are still an error', () {
      expect(() => liftSubject(heic), throwsFormatException);
    });
  });

  group('system cut-out (iOS Vision)', () {
    /// What the native side sends: transparent PNG, product in the middle.
    Uint8List systemPng({int w = 300, int h = 400, bool alpha = true}) {
      final im = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
      img.fillRect(im, x1: 100, y1: 100, x2: 199, y2: 299, color: img.ColorRgba8(30, 60, 160, 255));
      return img.encodePng(im);
    }

    final busy = _photo(
      w: 120,
      h: 120,
      paint: (im) {
        for (final p in im) {
          final v = (p.x * 37 + p.y * 91) % 255;
          p.setRgb(v, 255 - v, (v * 3) % 255);
        }
      },
    );

    test('wins over the flood fill, even on a photo the fill gives up on', () {
      final r = liftSubject(busy, system: systemPng());
      expect(r.cutout, isNotNull);
      // Trimmed to the product (100 x 200) plus the same 4 px padding.
      final out = img.decodePng(r.cutout!.png)!;
      expect((out.width, out.height), (108, 208));
      expect(out.getPixel(0, 0).a, 0);
      expect(out.getPixel(54, 104).a, 255);
      expect(r.original.cutout, isFalse, reason: 'the "Original" toggle still has the photo');
    });

    test('an unusable answer falls back to the flood fill', () {
      expect(liftSubject(busy, system: Uint8List.fromList([1, 2, 3])).cutout, isNull);
      expect(liftSubject(busy, system: systemPng(alpha: false)).cutout, isNull, reason: 'no transparency');
      expect(liftSubject(busy, system: img.encodePng(img.Image(width: 50, height: 50, numChannels: 4))).cutout, isNull,
          reason: 'nothing left');
    });

    test('a large system cut-out is held to the same 900 px', () {
      final r = liftSubject(busy, system: systemPng(w: 3000, h: 4000));
      final out = img.decodePng(r.cutout!.png)!;
      expect(out.height, lessThanOrEqualTo(900 + 8));
    });
  });
}
