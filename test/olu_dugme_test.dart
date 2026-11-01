import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/core/ui/widgets.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/counter/counter_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/item_detail_screen.dart';
import 'package:warranty_vault/features/reminders/reminders.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

/// Rafım Ar-Ge 24 Oct (yasin "düzelt ve gönder"): every button on the
/// product page and in "Something's wrong" does what it says. App Review
/// taps all of them (Guideline 2.1), and a promise the app does not keep is
/// 2.3.1.
final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<MemoryVaultStore> _open(WidgetTester t, {double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(demoVault());
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore({'region': 'DE', remindersAskedKey: '1'})),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => null),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
        child: const WarrantyVaultApp(),
      ),
    ),
  );
  await t.pumpAndSettle();
  return store;
}

Future<void> _openMac(WidgetTester t) async {
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute(builder: (_) => const ItemDetailScreen(itemId: 'macbook')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('the pencil opens the filled-in form; saving corrects the product and keeps its papers', (t) async {
    final store = await _open(t);
    await _openMac(t);
    await t.tap(find.byTooltip('Edit'));
    await t.pumpAndSettle();

    expect(find.text('Edit product'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'MacBook Air 13"'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Saturn Berlin'), findsOneWidget);
    expect(find.text('Put it on the shelf'), findsNothing);

    await t.enterText(find.widgetWithText(TextField, 'MacBook Air 13"'), 'MacBook Air M3');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    final mac = store.current.items.firstWhere((i) => i.id == 'macbook');
    expect(mac.name, 'MacBook Air M3');
    expect(mac.documents, hasLength(1), reason: 'the receipt stays with the product');
    expect(mac.photoPath, 'asset:kategori/laptop.png');
    expect(mac.purchase.region, 'DE');
    expect(mac.purchase.manufacturer.months, 12);
    expect(mac.price!.amount, 1299);
    expect(mac.shelfId, 'desk');
    expect(store.current.items.where((i) => i.name.startsWith('MacBook')), hasLength(1), reason: 'edited, not added');
    // Back on the product page, which shows the new name.
    expect(find.text('MacBook Air M3'), findsWidgets);
    expect(find.text("Something's wrong"), findsOneWidget);
  });

  testWidgets('a corrected purchase date moves the deadlines', (t) async {
    final store = await _open(t);
    final c = ProviderScope.containerOf(t.element(find.byType(WarrantyVaultApp)));
    Future<DateTime?> legalEnd() async =>
        (await c.read(itemViewProvider('macbook').future))!.protections
            .firstWhere((p) => p.kind == ProtectionKind.legal)
            .end;
    final before = await legalEnd();
    final old = store.current.items.firstWhere((i) => i.id == 'macbook');
    await c
        .read(vaultProvider.notifier)
        .edit(
          Item(
            id: old.id,
            name: old.name,
            store: old.store,
            category: old.category,
            price: old.price,
            shelfId: old.shelfId,
            purchase: Purchase(
              date: DateTime.utc(2025, 11, 10),
              region: old.purchase.region,
              channel: old.purchase.channel,
              manufacturer: old.purchase.manufacturer,
            ),
          ),
        );
    await t.pumpAndSettle();
    final after = await legalEnd();
    expect(after!.difference(before!).inDays, 365);
  });

  testWidgets('"Where does this period come from?" shows the official source', (t) async {
    await _open(t);
    await _openMac(t);
    await t.tap(find.textContaining('Worked out with'));
    await t.pumpAndSettle();
    expect(find.textContaining('This period comes from the consumer rules of'), findsOneWidget);
    final hosts = _rules.regions['DE']!.sources.map((u) => Uri.parse(u).host);
    expect(hosts, isNotEmpty);
    for (final h in hosts) {
      expect(find.text(h), findsWidgets);
    }
    final row = find.ancestor(of: find.text(hosts.first).first, matching: find.byType(InkWell)).first;
    expect(t.getSize(row).height, greaterThanOrEqualTo(44));
  });

  testWidgets('"Something\'s wrong" promises only what the app does and hands over the proof', (t) async {
    await _open(t);
    await _openMac(t);
    await t.tap(find.text("Something's wrong"));
    await t.pumpAndSettle();
    expect(find.textContaining('We write it'), findsNothing);
    expect(find.textContaining('draft the complaint'), findsNothing);
    expect(find.text('Continue'), findsNothing);
    await t.tap(find.widgetWithText(FilledButton, 'Show at the counter'));
    await t.pumpAndSettle();
    expect(find.byType(CounterScreen), findsOneWidget);
  });

  testWidgets('the edit form fits at the largest text size (3.1×)', (t) async {
    await _open(t, textScale: 3.1);
    await _openMac(t);
    await t.tap(find.byTooltip('Edit'));
    await t.pumpAndSettle();
    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('photos are decoded at the drawn size, in 64 px steps', () {
    const src = AssetImage('assets/kategori/laptop.png');
    final r = decodedAt(src, const Size(100, 60), 3) as ResizeImage;
    expect(r.width, 320);
    expect(r.height, 192);
    expect(r.policy, ResizeImagePolicy.fit);
    expect(decodedAt(src, const Size(double.infinity, 10), 3), same(src));
  });
}
