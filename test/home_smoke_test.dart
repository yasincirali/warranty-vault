import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/items/data/demo_item_repository.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/rights/rule_set.dart';

// Asset loading is real I/O and never settles under fake async; the same
// file is read synchronously instead.
final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// The design's reference day: MacBook has 28 days of legal right left,
/// the Sony bought online on 2 Oct has 3 days of its return window.
Widget app({double textScale = 1}) => ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        itemRepositoryProvider.overrideWithValue(DemoItemRepository()),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const WarrantyVaultApp(),
      ),
    );

void main() {
  testWidgets('home lists the two items that need attention, soonest first', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();

    expect(find.text('Needs attention · 2'), findsOneWidget);
    final sony = t.getTopLeft(find.text('Return window ends in 3 days'));
    final mac = t.getTopLeft(find.text('Legal right ends in 28 days'));
    expect(sony.dy, lessThan(mac.dy));
  });

  for (final scale in [2.0, 3.1]) {
    testWidgets('no overflow at ${scale}x text', (t) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(app(textScale: scale));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('detail answers first, problem flow gives one recommendation', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('MacBook Air 13"').first);
    await t.pumpAndSettle();
    expect(find.text("Something's wrong"), findsOneWidget);

    await t.tap(find.text("Something's wrong"));
    await t.pumpAndSettle();
    expect(find.text('What happened?'), findsOneWidget);
  });

  testWidgets('capture flags unsure fields with text, not only colour', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Add receipt or invoice'));
    await t.pumpAndSettle();
    expect(find.text('Is this right?'), findsOneWidget);
    expect(find.text("We're not sure, please check"), findsOneWidget);
  });
}
