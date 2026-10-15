import 'dart:io';

import 'package:flutter/material.dart';
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

Future<(MemoryVaultStore, MemorySettingsStore)> _open(WidgetTester t,
    {Map<String, String>? saved, double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final vault = MemoryVaultStore(demoVault());
  final settings = MemorySettingsStore(saved);
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(vault),
      settingsStoreProvider.overrideWithValue(settings),
      ruleSetProvider.overrideWith((_) async => _rules),
      photoPickerProvider.overrideWithValue((_) async => null),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
      child: const WarrantyVaultApp(),
    ),
  ));
  await t.pumpAndSettle();
  return (vault, settings);
}

void main() {
  testWidgets('choosing Türkçe switches the whole app and is remembered', (t) async {
    final (_, settings) = await _open(t);
    expect(find.text('My things'), findsOneWidget);
    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    await t.tap(find.text('Türkçe'));
    await t.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget, reason: 'the settings screen itself is now Turkish');
    expect(settings.read('language'), 'tr');

    await t.tap(find.text('Telefonun dili'));
    await t.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(settings.read('language'), isNull, reason: 'following the phone stores nothing');
  });

  testWidgets('a saved language is used from the first frame', (t) async {
    await _open(t, saved: {'language': 'tr'});
    expect(find.text('Eşyalarım'), findsOneWidget);
  });

  testWidgets('an unknown saved value falls back to the phone instead of breaking', (t) async {
    await _open(t, saved: {'language': 'xx', 'region': 'ZZ'});
    expect(find.text('My things'), findsOneWidget);
  });

  testWidgets('the chosen country is the default for new products', (t) async {
    final (vault, _) = await _open(t);
    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('United Kingdom'), 200);
    await t.tap(find.text('United Kingdom'));
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();

    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Kettle');
    await t.pump();
    await t.tap(find.text('Put it on the shelf'));
    await t.pumpAndSettle();
    expect(vault.current.items.firstWhere((i) => i.name == 'Kettle').purchase.region, 'GB');
  });

  testWidgets('settings fit at 3.1x text', (t) async {
    await _open(t, textScale: 3.1);
    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('About'), 300);
    expect(t.takeException(), isNull);
  });
}
