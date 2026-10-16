import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/export/exporter.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<(MemoryVaultStore, MemorySettingsStore)> _open(
  WidgetTester t, {
  Map<String, String>? saved,
  double textScale = 1,
  Vault? vault,
  List overrides = const [],
}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(vault ?? demoVault());
  final settings = MemorySettingsStore(saved);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(settings),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => null),
        ...overrides,
      ],
      child: MediaQuery(
        data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
        child: const WarrantyVaultApp(),
      ),
    ),
  );
  await t.pumpAndSettle();
  return (store, settings);
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

  group('export', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('export'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Opens Settings, taps [row] and waits (real time: file IO and image
    /// decoding don't run on the fake clock) for the share sheet.
    Future<(File, String)?> export(WidgetTester t, String row, {Vault? vault}) async {
      final shared = Completer<(File, String)>();
      await _open(
        t,
        vault: vault,
        overrides: [
          exportDirProvider.overrideWithValue(() async => dir),
          shareFileProvider.overrideWithValue((file, mime, origin) async {
            expect(origin.isEmpty, isFalse, reason: 'iPad anchors the share popover to the row');
            shared.complete((file, mime));
          }),
        ],
      );
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text(row), 300);
      await t.ensureVisible(find.text(row));
      await t.pumpAndSettle();
      await t.tap(find.text(row));
      await t.pump();
      // The export was started from the tap, inside the test's fake clock:
      // its file and image work needs real time and its callbacks need
      // pumps, so alternate the two until the share sheet is reached.
      for (var i = 0; i < 400 && !shared.isCompleted; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await t.pump();
      }
      expect(shared.isCompleted, isTrue, reason: 'the file reached the share sheet');
      await t.pumpAndSettle();
      return shared.future;
    }

    testWidgets('PDF report: a real PDF named by the date reaches the share sheet', (t) async {
      final (file, mime) = (await export(t, 'PDF report'))!;
      expect(file.path, endsWith('inventory-2026-10-13.pdf'));
      expect(mime, 'application/pdf');
      final bytes = await t.runAsync(file.readAsBytes);
      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    });

    testWidgets('Excel spreadsheet: an .xlsx (zip) reaches the share sheet', (t) async {
      final (file, mime) = (await export(t, 'Excel spreadsheet'))!;
      expect(file.path, endsWith('inventory-2026-10-13.xlsx'));
      expect(mime, contains('spreadsheetml'));
      final bytes = await t.runAsync(file.readAsBytes);
      expect(String.fromCharCodes(bytes!.take(2)), 'PK');
    });

    testWidgets('an empty cabinet says so instead of sharing an empty file', (t) async {
      await _open(
        t,
        vault: const Vault(),
        overrides: [
          exportDirProvider.overrideWithValue(() async => dir),
          shareFileProvider.overrideWithValue((_, _, _) async => fail('nothing to share')),
        ],
      );
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('PDF report'), 300);
      await t.ensureVisible(find.text('PDF report'));
      await t.pumpAndSettle();
      await t.tap(find.text('PDF report'));
      for (var i = 0; i < 10; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump();
      }
      await t.pumpAndSettle();
      expect(find.text('Nothing to export yet. Add a product first.'), findsOneWidget);
    });
  });
}
