import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// Stripes from edge to edge: no even background for the flood fill.
Uint8List _busy() {
  final im = img.Image(width: 120, height: 120);
  for (final p in im) {
    final on = (p.x ~/ 6).isEven;
    p.setRgb(on ? 250 : 10, on ? 30 : 200, 40);
  }
  return img.encodePng(im);
}

void main() {
  // yasin, 18 Oct: "hala algılayamıyor" on TestFlight with no way to tell
  // which step failed. The system lift's reason now shows under the photo.
  Future<void> pick(WidgetTester t, SystemLift system) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final photo = _busy();
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => photo),
        systemLiftProvider.overrideWithValue((_) async => system),
      ],
      child: const WarrantyVaultApp(),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.byIcon(Icons.photo_library_outlined));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await t.pumpAndSettle();
  }

  testWidgets('an uncut photo names why the system lift gave nothing', (t) async {
    await pick(t, (png: null, why: 'no_subject'));
    expect(find.textContaining("wasn't clear enough"), findsOneWidget);
    expect(find.text('no_subject'), findsOneWidget);
  });

  testWidgets("the system's cut-out reaches the screen through the real isolate", (t) async {
    final cut = img.Image(width: 60, height: 60, numChannels: 4);
    img.fillRect(cut, x1: 10, y1: 10, x2: 50, y2: 50, color: img.ColorRgba8(200, 40, 40, 255));
    await pick(t, (png: img.encodePng(cut), why: null));
    expect(find.text('Cut out'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.textContaining("wasn't clear enough"), findsNothing);
  });
}
