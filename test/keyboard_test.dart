import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// iPhone 15 portrait; the keyboard is 336 pt tall when up.
const _keyboard = 336.0;

Future<MemoryVaultStore> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final s = MemoryVaultStore(demoVault());
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(s),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => null),
      ],
      child: const WarrantyVaultApp(),
    ),
  );
  await t.pumpAndSettle();
  return s;
}

/// What the system does when a field takes focus: the keyboard slides up.
Future<void> _keyboardUp(WidgetTester t) async {
  t.view.viewInsets = const FakeViewPadding(bottom: _keyboard * 3);
  await t.pumpAndSettle();
}

Future<void> _keyboardDown(WidgetTester t) async {
  t.view.resetViewInsets();
  await t.pumpAndSettle();
}

bool _hasFocus(WidgetTester t, Finder field) =>
    t.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText))).focusNode.hasFocus;

const _screen = 852.0;

void main() {
  group('add screen', () {
    Future<void> openAdd(WidgetTester t) async {
      await _open(t);
      await t.tap(find.text('Add a product'));
      await t.pumpAndSettle();
    }

    testWidgets('the save button rides above the keyboard, with a hide-keyboard button next to it', (t) async {
      await openAdd(t);
      expect(find.byTooltip('Hide keyboard'), findsNothing, reason: 'no keyboard, nothing to hide');

      final name = find.widgetWithText(TextField, 'Product');
      await t.tap(name);
      await _keyboardUp(t);
      final save = find.widgetWithText(FilledButton, 'Put it on the shelf');
      expect(t.getRect(save).bottom, lessThanOrEqualTo(_screen - _keyboard));
      expect(find.byTooltip('Hide keyboard'), findsOneWidget);
      expect(t.getSize(find.byTooltip('Hide keyboard')).height, greaterThanOrEqualTo(44));

      await t.tap(find.byTooltip('Hide keyboard'));
      await t.pump();
      expect(_hasFocus(t, name), isFalse);
      await _keyboardDown(t);
      expect(find.byTooltip('Hide keyboard'), findsNothing);
    });

    testWidgets('a tap outside the fields closes the keyboard; moving between fields does not', (t) async {
      await openAdd(t);
      final name = find.widgetWithText(TextField, 'Product');
      final store = find.widgetWithText(TextField, 'Store');
      await t.tap(name);
      await t.pump();
      await t.tap(store);
      await t.pump();
      expect(_hasFocus(t, store), isTrue);
      expect(t.testTextInput.isVisible, isTrue, reason: 'the keyboard stayed up between fields');

      await t.tapAt(t.getTopLeft(find.text('New product')));
      await t.pump();
      expect(_hasFocus(t, store), isFalse);
    });

    testWidgets('next goes name → store → amount, done on the amount closes the keyboard', (t) async {
      await openAdd(t);
      final name = find.widgetWithText(TextField, 'Product');
      final amount = find.widgetWithText(TextField, 'Amount');
      await t.tap(name);
      await t.pump();
      await t.testTextInput.receiveAction(TextInputAction.next);
      await t.pump();
      expect(_hasFocus(t, find.widgetWithText(TextField, 'Store')), isTrue);
      await t.testTextInput.receiveAction(TextInputAction.next);
      await t.pump();
      expect(_hasFocus(t, amount), isTrue);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(_hasFocus(t, amount), isFalse);
    });

    testWidgets('the focused amount and its read-back line sit above the keyboard', (t) async {
      await openAdd(t);
      final amount = find.widgetWithText(TextField, 'Amount');
      await t.tap(amount);
      await t.enterText(amount, '1.299,90');
      await _keyboardUp(t);
      final barTop = t.getRect(find.widgetWithText(FilledButton, 'Put it on the shelf')).top;
      expect(t.getRect(amount).bottom, lessThan(barTop));
      expect(t.getRect(find.textContaining('1,299.90')).bottom, lessThan(barTop));
    });

    testWidgets('scrolling the form closes the keyboard', (t) async {
      await openAdd(t);
      final name = find.widgetWithText(TextField, 'Product');
      await t.tap(name);
      await t.pump();
      await t.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await t.pumpAndSettle();
      expect(_hasFocus(t, name), isFalse);
    });
  });

  group('shelf label', () {
    Future<void> editBottomLabel(WidgetTester t) async {
      final add = find.text('+ Label');
      await t.ensureVisible(add);
      await t.pumpAndSettle();
      await t.tap(add);
      await t.pumpAndSettle();
    }

    testWidgets('a tap elsewhere ends the edit and keeps the text', (t) async {
      final store = await _open(t);
      await editBottomLabel(t);
      await t.enterText(find.byType(TextField), 'Camping');
      await t.tapAt(const Offset(40, 70)); // the page title
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(store.current.shelves.map((s) => s.label), contains('Camping'));
    });

    testWidgets('the label being written is lifted above the keyboard', (t) async {
      await _open(t);
      await editBottomLabel(t);
      await _keyboardUp(t);
      expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(_screen - _keyboard));
    });
  });
}
