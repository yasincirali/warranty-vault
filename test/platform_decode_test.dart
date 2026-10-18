import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/capture/subject_lift.dart';

void main() {
  testWidgets('the phone codec path scales to the shelf size and keeps the shape', (t) async {
    final png = img.encodePng(img.Image(width: 1800, height: 1200));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final raw = await t.runAsync(() => container.read(platformDecodeProvider)(png));
    expect(raw, isNotNull);
    expect(raw!.width, maxPhotoSide);
    expect(raw.height, 600);
    expect(raw.rgba.length, 900 * 600 * 4);
  });

  testWidgets('bytes the phone cannot read either give null, not a crash', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final raw = await t.runAsync(() => container.read(platformDecodeProvider)(Uint8List(32)));
    expect(raw, isNull);
  });
}
