import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/core/theme/tokens.dart';
import 'package:warranty_vault/core/ui/time_rule.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/item_detail_screen.dart';
import 'package:warranty_vault/features/items/ui/item_photo.dart';
import 'package:warranty_vault/features/reminders/reminders.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

/// Rafım Ar-Ge 25 Oct (yasin "yap"): the visual and UX round.
final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// The demo cabinet plus a TV bought in 2021, every protection over.
Vault _vault() {
  final d = demoVault();
  return Vault(shelves: d.shelves, items: [
    ...d.items,
    Item(
      id: 'old-tv',
      name: 'Old TV',
      store: 'MediaMarkt',
      category: ItemCategory.tv,
      shelfId: d.shelves[1].id,
      purchase: Purchase(
        date: DateTime.utc(2021, 3, 1),
        region: 'DE',
        channel: SalesChannel.store,
        manufacturer: const ManufacturerWarranty.months(24),
      ),
    ),
  ]);
}

Future<void> _open(WidgetTester t, {bool reduceMotion = false, double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(_vault())),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore({'region': 'DE', remindersAskedKey: '1'})),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 852),
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const WarrantyVaultApp(),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Finder _onShelf(String id) => find.byKey(ValueKey('item-$id'));

void main() {
  testWidgets('every protection is a band on one shared time axis, today at the same x on each', (t) async {
    await _open(t);
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ItemDetailScreen(itemId: 'macbook')));
    await t.pumpAndSettle();
    final bands = t.widgetList<TimeBand>(find.byType(TimeBand)).toList();
    expect(bands, hasLength(2), reason: 'legal right and maker warranty');
    expect(bands.map((b) => b.axisStart).toSet(), hasLength(1));
    expect(bands.map((b) => b.axisEnd).toSet(), {DateTime.utc(2026, 11, 10)});
    // The words stay: each band sits under its row's sentence.
    expect(find.textContaining('Nov 10, 2026'), findsWidgets);
  });

  test('no axis when nothing has a fixed end', () {
    final p = Protection(
      kind: ProtectionKind.manufacturer,
      start: DateTime.utc(2026),
      end: null,
      status: ProtectionStatus.active,
    );
    expect(TimeBand.axisOf([p]), isNull);
  });

  testWidgets('the photo flies between its shelf and its page under one tag', (t) async {
    await _open(t);
    expect(find.byWidgetPredicate((w) => w is Hero && w.tag == itemHeroTag('sony')), findsOneWidget);
    await t.tap(find.text('Sony WH-1000XM5').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    // Mid-flight: the shuttle is in the overlay.
    expect(find.byWidgetPredicate((w) => w is Hero && w.tag == itemHeroTag('sony')), findsWidgets);
    await t.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('with reduce motion the page just opens', (t) async {
    await _open(t, reduceMotion: true);
    final mode = t.widgetList<HeroMode>(find.byType(HeroMode)).where((m) => !m.enabled);
    expect(mode, isNotEmpty);
  });

  testWidgets('a product with every protection over greys on its shelf; a covered one does not', (t) async {
    await _open(t);
    bool grey(String id) => find
        .descendant(of: _onShelf(id), matching: find.byType(ColorFiltered))
        .evaluate()
        .isNotEmpty;
    expect(grey('old-tv'), isTrue);
    expect(grey('sony'), isFalse);
    expect(find.bySemanticsLabel(RegExp('Old TV.*')), findsWidgets);
  });

  testWidgets('shelf labels are white tape, not the primary action\'s black', (t) async {
    await _open(t);
    final ctx = t.element(find.byType(WarrantyVaultApp));
    final tape = t
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius == BorderRadius.circular(3) && d.color != null);
    expect(tape, isNotEmpty);
    for (final d in tape) {
      expect(d.color, isNot(Theme.of(ctx).brightness == Brightness.light ? VColors.light.text : VColors.dark.text));
    }
  });

  testWidgets('the product page with its bands fits at the largest text size (3.1×)', (t) async {
    await _open(t, textScale: 3.1);
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ItemDetailScreen(itemId: 'macbook')));
    await t.pumpAndSettle();
    for (var i = 0; i < 20 && find.byType(TimeBand).evaluate().isEmpty; i++) {
      await t.drag(
        find.descendant(of: find.byType(ItemDetailScreen), matching: find.byType(Scrollable)).first,
        const Offset(0, -400),
      );
      await t.pumpAndSettle();
    }
    expect(find.byType(TimeBand), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
