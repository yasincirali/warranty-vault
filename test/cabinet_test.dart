import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/cabinet/cabinet_view.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<MemoryVaultStore> _open(WidgetTester t, {bool reduceMotion = false, MemoryVaultStore? store}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final s = store ?? MemoryVaultStore(demoVault());
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(s),
      ruleSetProvider.overrideWith((_) async => _rules),
      photoPickerProvider.overrideWithValue((_) async => null),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: const Size(393, 852), disableAnimations: reduceMotion),
      child: const WarrantyVaultApp(),
    ),
  ));
  await t.pumpAndSettle();
  return s;
}

Finder _onShelf(String name) => find.descendant(of: find.byType(CabinetView), matching: find.text(name));

/// Sample products show their picture, not their name.
Finder _product(String id) => find.byKey(ValueKey('item-$id'));

String? _shelfOf(MemoryVaultStore s, String id) => s.current.items.firstWhere((i) => i.id == id).shelfId;

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('dragging a product onto the next shelf moves it there', (t) async {
    final store = await _open(t);
    final mac = _product('macbook');
    await t.ensureVisible(mac);
    await t.pumpAndSettle();
    expect(_shelfOf(store, 'macbook'), 'desk');

    final g = await t.startGesture(t.getCenter(mac));
    for (var i = 0; i < 30; i++) {
      await g.moveBy(const Offset(4, 6));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _frames(t, 10);
    await g.up();
    await t.pumpAndSettle();

    expect(_shelfOf(store, 'macbook'), 'living');
    expect(t.takeException(), isNull);
  });

  testWidgets('flicking a product sideways throws it out, undo puts it back', (t) async {
    final store = await _open(t);
    final sony = _product('sony');
    await t.ensureVisible(sony);
    await t.pumpAndSettle();

    await t.fling(sony, const Offset(260, -10), 2400);
    await _frames(t, 90);
    await t.pumpAndSettle();

    expect(store.current.disposed.map((i) => i.id), ['sony']);
    expect(find.text('Sony WH-1000XM5 is out of the cabinet'), findsOneWidget);
    expect(find.text('Thrown out · 1'), findsOneWidget);

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(store.current.disposed, isEmpty);
    expect(_shelfOf(store, 'sony'), 'desk');
  });

  testWidgets('a slow drag sideways is never a throw', (t) async {
    final store = await _open(t);
    final pixel = _product('pixel');
    await t.ensureVisible(pixel);
    await t.pumpAndSettle();
    final g = await t.startGesture(t.getCenter(pixel));
    for (var i = 0; i < 40; i++) {
      await g.moveBy(const Offset(-3, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pumpAndSettle();
    expect(store.current.disposed, isEmpty);
  });

  testWidgets('tapping a product opens its rights', (t) async {
    await _open(t);
    final bosch = _product('bosch');
    await t.ensureVisible(bosch);
    await t.pumpAndSettle();
    await t.tap(bosch);
    await t.pumpAndSettle();
    expect(find.text('Where you stand today'), findsOneWidget);
  });

  testWidgets('a shelf label can be written on the empty bottom shelf', (t) async {
    final store = await _open(t);
    final add = find.text('+ Label');
    await t.ensureVisible(add);
    await t.pumpAndSettle();
    await t.tap(add);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Camping');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(store.current.shelves.map((s) => s.label), contains('Camping'));
    expect(store.current.shelves.last.label, isEmpty, reason: 'a fresh empty shelf stays at the bottom');
  });

  testWidgets('screen readers get move and throw-out actions on every product', (t) async {
    final semantics = t.ensureSemantics();
    final store = await _open(t);
    final node = t.getSemantics(find.ancestor(of: _product('bosch'), matching: find.byType(Semantics)).first);
    final actions = node.getSemanticsData().customSemanticsActionIds;
    expect(actions, isNotNull);
    expect(actions!.length, 3);
    expect(node.label, contains('Kitchen'));
    expect(store.current.disposed, isEmpty);
    semantics.dispose();
  });

  testWidgets('adding a product without a photo puts it on a shelf', (t) async {
    final store = await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    expect(find.text('New product'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Moka pot');
    await t.enterText(find.widgetWithText(TextField, 'Amount'), '1.299,90');
    await t.pump();
    await t.tap(find.text('Put it on the shelf'));
    await t.pumpAndSettle();

    final moka = store.current.items.firstWhere((i) => i.name == 'Moka pot');
    expect(moka.price!.amount, 1299.9);
    expect(moka.shelfId, isNotNull);
    expect(_onShelf('Moka pot'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a product without a photo stands on its shelf as its kind\'s drawing, with its name', (t) async {
    final semantics = t.ensureSemantics();
    final store = await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Dyson V15');
    await t.pumpAndSettle();
    // Guessed from the name until the user picks.
    expect(_kindSelected(t, 'Vacuum'), isTrue);
    await t.tap(find.bySemanticsLabel('Appliance, kind'));
    await t.pumpAndSettle();
    expect(_kindSelected(t, 'Vacuum'), isFalse);
    expect(_kindSelected(t, 'Appliance'), isTrue);
    await t.tap(find.text('Put it on the shelf'));
    await t.pumpAndSettle();

    final item = store.current.items.firstWhere((i) => i.name == 'Dyson V15');
    expect(item.category, ItemCategory.appliance);
    final drawing = find.descendant(
      of: find.byType(CabinetView),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/kategori/appliance.png',
      ),
    );
    expect(drawing, findsOneWidget);
    expect(_onShelf('Dyson V15'), findsOneWidget, reason: 'its name tag');
    expect(t.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a new product falls in from above after the add screen has gone, onto its shelf', (t) async {
    final store = await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Kettle');
    await t.pump();
    await t.tap(find.text('Put it on the shelf'));

    final kettle = find.descendant(of: find.byType(CabinetView), matching: find.text('Kettle'));
    double? firstTop;
    for (var i = 0; i < 120 && firstTop == null; i++) {
      await t.pump(const Duration(milliseconds: 16));
      if (kettle.evaluate().isNotEmpty) {
        // Not while the add screen still covers the cabinet.
        expect(find.text('New product'), findsNothing);
        firstTop = t.getTopLeft(kettle).dy;
      }
    }
    expect(firstTop, isNotNull);
    await t.pumpAndSettle();

    final id = store.current.items.firstWhere((i) => i.name == 'Kettle').id;
    expect(t.getTopLeft(kettle).dy, greaterThan(firstTop! + 40), reason: 'it fell, it did not appear in place');
    // It came to rest standing on its own shelf's plank.
    expect(_shelfOf(store, id), isNotNull);
    expect(t.takeException(), isNull);
  });

  testWidgets('the amount is read back as it will be saved', (t) async {
    await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Amount'), '1.299,90');
    await t.pumpAndSettle();
    expect(find.textContaining('1,299.90'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'Amount'), 'abc');
    await t.pumpAndSettle();
    expect(find.text("Couldn't read the amount; use digits."), findsOneWidget);
  });

  testWidgets('the sales channel switches with one tap on the sliding control', (t) async {
    final store = await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Lamp');
    // The form's list, not one of the text fields' own horizontal scrollers.
    await t.scrollUntilVisible(
      find.text('Online'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
    );
    await t.tap(find.text('Online'));
    await t.pumpAndSettle();
    await t.tap(find.text('Put it on the shelf'));
    await t.pumpAndSettle();
    expect(store.current.items.firstWhere((i) => i.name == 'Lamp').purchase.channel, SalesChannel.online);
  });

  testWidgets('the save button waits for a name', (t) async {
    await _open(t);
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    final button = t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Put it on the shelf'));
    expect(button.onPressed, isNull);
  });

  testWidgets('the kind picker fits at 3.1x text without overflow', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => null),
      ],
      child: const MediaQuery(
        data: MediaQueryData(size: Size(393, 852), textScaler: TextScaler.linear(3.1)),
        child: WarrantyVaultApp(),
      ),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('Other'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    // Every kind is a 44-pt-or-larger target.
    for (final c in ['Laptop', 'Phone', 'Headphones', 'TV', 'Appliance', 'Vacuum', 'Other']) {
      final box = t.getSize(find.ancestor(of: find.text(c), matching: find.byType(GestureDetector)).first);
      expect(box.width, greaterThanOrEqualTo(44));
      expect(box.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('cabinet fits at 3.1x text without overflow', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: const MediaQuery(
        data: MediaQueryData(size: Size(393, 852), textScaler: TextScaler.linear(3.1)),
        child: WarrantyVaultApp(),
      ),
    ));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('+ Label'), 200);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  test('amounts parse in Turkish, German and English notation', () {
    expect(parseAmount('1.299,90'), 1299.9);
    expect(parseAmount('1,299.90'), 1299.9);
    expect(parseAmount('1.299'), 1299);
    expect(parseAmount('49,5'), 49.5);
    expect(parseAmount('₺ 54.999'), 54999);
    expect(parseAmount(''), isNull);
  });

  testWidgets('with reduce motion a product appears on its shelf without falling', (t) async {
    final store = await _open(t, reduceMotion: true, store: MemoryVaultStore(demoVault()));
    await t.tap(find.text('Add a product'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Product'), 'Kettle');
    await t.pump();
    await t.tap(find.text('Put it on the shelf'));
    await t.pumpAndSettle();
    expect(store.current.items.any((i) => i.name == 'Kettle'), isTrue);
    // Already standing on its plank: the body is grounded, not falling.
    final kettle = _onShelf('Kettle');
    await t.ensureVisible(kettle);
    await t.pumpAndSettle();
    final before = t.getCenter(kettle);
    await _frames(t, 10);
    expect(t.getCenter(kettle), before);
  });
}

bool _kindSelected(WidgetTester t, String kind) =>
    isSemantics(isSelected: true).matches(t.getSemantics(find.bySemanticsLabel('$kind, kind')), {});
