import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/cabinet/cabinet_view.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/search/search.dart';
import 'package:warranty_vault/features/search/search_screen.dart';
import 'package:warranty_vault/rights/rights_engine.dart';

import 'home_smoke_test.dart' show app;

SearchEntry _e(String name, {DateTime? end, ProtectionStatus status = ProtectionStatus.active, bool none = false}) {
  final item = Item(
    id: name,
    name: name,
    store: '',
    purchase: Purchase(date: DateTime.utc(2026, 1, 1), region: 'TR', channel: SalesChannel.store),
  );
  final p = Protection(kind: ProtectionKind.manufacturer, start: DateTime.utc(2026, 1, 1), end: end, status: status);
  return SearchEntry(ItemView(item, none ? const [] : [p], null), name, name);
}

void main() {
  test('empty search lists soonest end first, open-ended next, ended last', () {
    final index = [
      _e('bitti', end: DateTime.utc(2026, 3, 1), status: ProtectionStatus.ended),
      _e('ömür boyu'),
      _e('aralık', end: DateTime.utc(2026, 12, 1)),
      _e('korumasız', none: true),
      _e('kasım', end: DateTime.utc(2026, 11, 1)),
    ];
    expect([for (final v in soonestEnding(index)) v.item.name], ['kasım', 'aralık', 'ömür boyu', 'bitti', 'korumasız']);
  });

  testWidgets('search opens on the soonest-ending list, typing replaces it', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Search'));
    await t.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Ending soonest first'), findsOneWidget);
    // The demo Sony's return window (3 days) ends before the MacBook's legal right.
    final rows = find.descendant(of: find.byType(ListView), matching: find.byType(InkWell));
    expect(rows, findsWidgets);
    await t.enterText(find.byType(TextField), 'zzzz');
    await t.pumpAndSettle();
    expect(find.text('Ending soonest first'), findsNothing);
  });

  testWidgets('the dashed place on the empty shelf opens the add screen', (t) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(store: MemoryVaultStore()));
    await t.pumpAndSettle();
    // Button and dashed place: the same words, the same action.
    expect(find.bySemanticsLabel('Add a product'), findsNWidgets(2));
    semantics.dispose();
    await t.tap(find.descendant(of: find.byType(EmptyCabinet), matching: find.byType(InkWell)));
    await t.pumpAndSettle();
    expect(find.byType(AddItemScreen), findsOneWidget);
  });

  for (final scale in [1.0, 3.1]) {
    testWidgets('empty home has no overflow at ${scale}x text', (t) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(app(store: MemoryVaultStore(), textScale: scale));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('Try the sample shelves'), 200, scrollable: find.byType(Scrollable).first);
      expect(t.takeException(), isNull);
    });
  }
}
