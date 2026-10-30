import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/core/theme/app_theme.dart';
import 'package:warranty_vault/core/theme/tokens.dart';
import 'package:warranty_vault/core/ui/time_rule.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/documents.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<MemoryVaultStore> _open(WidgetTester t, {double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(demoVault());
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(store),
      ruleSetProvider.overrideWith((_) async => _rules),
      docPickerProvider.overrideWithValue((_) async => (bytes: File('assets/demo/fis_macbook.jpg').readAsBytesSync(), extension: 'jpg')),
    ],
    child: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(textScale)), child: const WarrantyVaultApp()),
  ));
  await t.pumpAndSettle();
  return store;
}

Future<void> _openSony(WidgetTester t) async {
  await t.ensureVisible(find.text('Sony WH-1000XM5').first);
  await t.pumpAndSettle();
  await t.tap(find.text('Sony WH-1000XM5').first);
  await t.pumpAndSettle();
}

Item _item(String id, String store, {bool sample = false, DateTime? date}) => Item(
      id: id,
      name: id,
      store: store,
      sample: sample,
      purchase: Purchase(date: date ?? DateTime.utc(2026, 1, 1), region: 'DE', channel: SalesChannel.store),
    );

void main() {
  test('store suggestions: most used first, own products only, at most three', () {
    final items = [
      _item('a', 'Amazon.de'),
      _item('b', 'amazon.de '),
      _item('c', 'MediaMarkt', date: DateTime.utc(2026, 5, 1)),
      _item('d', 'Saturn', date: DateTime.utc(2026, 2, 1)),
      _item('e', 'Otto', date: DateTime.utc(2026, 1, 2)),
      _item('f', 'Sample shop', sample: true),
      _item('g', 'Sample shop', sample: true),
      _item('h', ''),
    ];
    // Amazon twice; then ties broken by the shop used last.
    expect(frequentStores(items), ['Amazon.de', 'MediaMarkt', 'Saturn']);
  });

  testWidgets('a store chip fills the field; typing filters the chips', (t) async {
    await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'Store');
    await t.ensureVisible(field);
    await t.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing, reason: 'hidden until the field has focus');
    await t.tap(field);
    await t.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Amazon.de'), findsOneWidget);
    final first = t.widget<Text>(find.descendant(of: find.byType(ActionChip).first, matching: find.byType(Text))).data!;
    await t.tap(find.byType(ActionChip).first);
    await t.pumpAndSettle();
    expect(t.widget<TextField>(field).controller!.text, first);
    expect(find.widgetWithText(ActionChip, first), findsNothing, reason: 'what is typed is not offered again');
    await t.tap(field);
    await t.enterText(field, 'zzz');
    await t.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('the photo box no longer repeats that a photo is optional', (t) async {
    await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    expect(find.textContaining('Without a photo'), findsOneWidget, reason: 'said once, under the drawings');
  });

  testWidgets('counter without a receipt adds one in place', (t) async {
    final store = await _open(t);
    await _openSony(t);
    final counter = find.text('Show at the counter');
    await t.scrollUntilVisible(counter, 200, scrollable: find.byType(Scrollable).last);
    await t.tap(counter);
    await t.pumpAndSettle();
    expect(find.textContaining('Purchase details'), findsOneWidget, reason: 'no "proof" without one');
    expect(find.text('Add the receipt or invoice'), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.text('Choose from photos'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    final sony = store.current.items.firstWhere((i) => i.name == 'Sony WH-1000XM5');
    expect(sony.receipt, isNotNull);
    expect(find.text('Add the receipt or invoice'), findsNothing);
    expect(find.textContaining('Proof of purchase'), findsOneWidget);
  });

  testWidgets('counter add-proof fits at 3.1x text', (t) async {
    await _open(t, textScale: 3.1);
    await _openSony(t);
    final counter = find.text('Show at the counter');
    await t.scrollUntilVisible(counter, 200, scrollable: find.byType(Scrollable).last);
    await t.tap(counter);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Choose from photos'), 200, scrollable: find.byType(Scrollable).last);
    expect(t.takeException(), isNull);
  });

  testWidgets('a short window is a visible piece with its days in words', (t) async {
    await _open(t);
    await _openSony(t);
    final bands = find.byType(TimeBand);
    final returns = bands.first;
    final piece = find.descendant(of: returns, matching: find.byType(Container)).first;
    expect(t.getSize(piece).width, greaterThanOrEqualTo(TimeBand.minSpan));
    expect(find.descendant(of: returns, matching: find.text('3 days')), findsOneWidget);
  });

  testWidgets('whose rules apply is a line, not a pill that looks tappable', (t) async {
    await _open(t);
    await _openSony(t);
    final note = find.text('Worked out with Germany rules');
    expect(note, findsOneWidget);
    expect(find.ancestor(of: note, matching: find.byType(InkWell)), findsNothing);
  });

  test('sheets sit on the app paper, not a tinted surface', () {
    for (final b in Brightness.values) {
      final theme = buildTheme(b);
      final c = theme.extension<VColors>()!;
      expect(theme.bottomSheetTheme.backgroundColor, c.background);
      expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    }
  });

}
