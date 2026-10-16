import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/ui/widgets.dart';
import 'package:warranty_vault/features/capture/category_guess.dart';
import 'package:warranty_vault/features/items/domain/item.dart';

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(String path) {
  final b = ByteData.sublistView(File(path).readAsBytesSync());
  return (b.getUint32(16), b.getUint32(20));
}

void main() {
  test('every kind has a drawing, and its recorded aspect is the drawing\'s', () {
    for (final c in ItemCategory.values) {
      final path = CategoryArt.asset(c);
      expect(File(path).existsSync(), isTrue, reason: path);
      final (w, h) = _pngSize(path);
      expect(CategoryArt.aspect(c), closeTo(w / h, .01), reason: '${c.name}: ${w}x$h');
    }
  });

  test('the kind is guessed from what people type', () {
    expect(guessCategory('MacBook Air 13"'), ItemCategory.laptop);
    expect(guessCategory('Lenovo dizüstü'), ItemCategory.laptop);
    expect(guessCategory('iPhone 16 Pro'), ItemCategory.phone);
    expect(guessCategory('Pixel 9'), ItemCategory.phone);
    expect(guessCategory('Pixel Buds Pro'), ItemCategory.headphones);
    expect(guessCategory('Sony WH-1000XM5'), ItemCategory.headphones);
    expect(guessCategory('KULAKLIK'), ItemCategory.headphones);
    expect(guessCategory('LG OLED C3'), ItemCategory.tv);
    expect(guessCategory('Samsung TV'), ItemCategory.tv);
    expect(guessCategory('Bosch çamaşır makinesi'), ItemCategory.appliance);
    expect(guessCategory('Dyson V12'), ItemCategory.vacuum);
    expect(guessCategory('Robot süpürge'), ItemCategory.vacuum);
    expect(guessCategory('Etvos krem'), isNull, reason: '"tv" only as a whole word');
    expect(guessCategory('Moka pot'), isNull);
    expect(guessCategory(''), isNull);
  });
}
