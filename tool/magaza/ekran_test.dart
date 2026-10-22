// App Store screenshots (6.9" iPhone, 1320×2868). The app launches globally
// (yasin 2026-10-22), so every store language gets its own set.
// Run: SHOT_OUT=store_listing/ekran/tr flutter test tool/magaza/ekran_test.dart
//      SHOT_LANG=en SHOT_OUT=store_listing/ekran/en flutter test tool/magaza/ekran_test.dart
// Not under test/: it writes files and needs SHOT_OUT.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());
final out = Platform.environment['SHOT_OUT']!;
final lang = Platform.environment['SHOT_LANG'] ?? 'tr';

Future<void> fonts() async {
  const m = '/opt/flutter/bin/cache/artifacts/material_fonts';
  for (final fam in ['Roboto', 'FlutterTest', 'Ahem', '.SF Pro Text', '.SF Pro Display', 'CupertinoSystemText', 'CupertinoSystemDisplay', 'Inter', 'InterDisplay', '.SF UI Text', '.SF UI Display']) {
    final r = FontLoader(fam);
    for (final f in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']) {
      r.addFont(Future.value(ByteData.sublistView(File('$m/$f.ttf').readAsBytesSync())));
    }
    for (final f in ['Inter-Regular', 'Inter-SemiBold', 'InterDisplay-Bold']) {
      r.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f.ttf').readAsBytesSync())));
    }
    await r.load();
  }
  final i = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$m/MaterialIcons-Regular.otf').readAsBytesSync())));
  await i.load();
}

Future<void> shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final img = await (t.binding.renderViews.first.debugLayer! as OffsetLayer)
        .toImage(Offset.zero & t.view.physicalSize, pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('store shots', (t) async {
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump();
      }
      await t.pumpAndSettle();
    }
    await t.runAsync(fonts);
    t.view.physicalSize = const Size(1320, 2868);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore({'language': lang})),
        vaultStoreProvider.overrideWithValue(
            MemoryVaultStore(lang == 'tr'
                ? demoVault(desk: 'Çalışma masası', living: 'Salon', kitchen: 'Mutfak')
                : demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => File('assets/kategori/headphones.png').readAsBytesSync()),
        systemLiftProvider.overrideWithValue((b) async => (png: b, why: null)),
        photoLabelsProvider.overrideWithValue((_) async => [('headphones', .8)]),
      ],
      child: const WarrantyVaultApp(),
    ));
    await t.pumpAndSettle();
    await settle();
    await shot(t, '1_dolap');
    // 2: the rights timeline of the headphones (return ends in 3 days).
    await t.tap(find.text('Sony WH-1000XM5').first);
    await t.pumpAndSettle();
    await settle();
    await shot(t, '2_haklar');
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    // 3: adding a product from a photo: cut out, kind guessed.
    await t.tap(find.text(lang == 'tr' ? 'Ürün ekle' : 'Add a product'));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.byIcon(Icons.photo_library_outlined));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await t.pumpAndSettle();
    await settle();
    await shot(t, '3_ekle');
  });
}
