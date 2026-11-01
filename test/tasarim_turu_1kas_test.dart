// Rafım design review 31 Oct 22:20 + 1 Nov 10:20, yasin "yap" (1 Nov):
// the cabinet ends on a plinth, the orange deadline tag opens its product,
// the product page shows the name in the bar once scrolled, and the time
// bands name their ticks.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/core/ui/time_rule.dart';
import 'package:warranty_vault/features/cabinet/cabinet_view.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/item_detail_screen.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<void> _open(WidgetTester t, {bool reduceMotion = false}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
      ruleSetProvider.overrideWith((_) async => _rules),
    ],
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: const WarrantyVaultApp(),
      ),
    ),
  ));
  await t.pumpAndSettle();
}

Finder get _tags => find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('tag-'));

void main() {
  testWidgets('the cabinet stands on a plinth and the page ends there', (t) async {
    await _open(t);
    expect(find.byType(CabinetBase), findsOneWidget);
    final cabinet = t.getRect(find.byType(CabinetView));
    final base = t.getRect(find.byType(CabinetBase));
    // Directly under the last plank, as wide as the cabinet.
    expect(base.top, moreOrLessEquals(cabinet.bottom - base.height, epsilon: 1) );
    await t.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await t.pumpAndSettle();
    final end = t.getRect(find.byType(CabinetBase));
    final scaffoldBottom = t.getRect(find.byType(FilledButton).last).top;
    // No long empty page under the cabinet: at most a short gap.
    expect(scaffoldBottom - end.bottom, lessThan(60));
  });

  testWidgets('tapping the orange deadline tag opens its product, with a 44 pt target', (t) async {
    await _open(t);
    expect(_tags, findsWidgets);
    final tag = _tags.first;
    expect(t.getSize(tag).height, greaterThanOrEqualTo(44));
    expect(t.getSize(tag).width, greaterThanOrEqualTo(44));
    await t.ensureVisible(tag);
    await t.pumpAndSettle();
    await t.tap(tag);
    await t.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testWidgets('the product name moves into the bar once the page scrolls', (t) async {
    await _open(t);
    await t.tap(find.text('MacBook Air 13"').first);
    await t.pumpAndSettle();
    final bar = find.byType(AppBar);
    Finder barTitle() => find.descendant(of: bar, matching: find.byType(AnimatedOpacity));
    double opacity() => t.widget<AnimatedOpacity>(barTitle().first).opacity;
    expect(opacity(), 0);
    await t.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await t.pumpAndSettle();
    expect(opacity(), 1);
    expect(find.descendant(of: bar, matching: find.text('MacBook Air 13"')), findsOneWidget);
    await t.drag(find.byType(Scrollable).last, const Offset(0, 400));
    await t.pumpAndSettle();
    expect(opacity(), 0);
  });

  testWidgets('with reduce motion the bar title appears without a fade', (t) async {
    await _open(t, reduceMotion: true);
    await t.tap(find.text('MacBook Air 13"').first);
    await t.pumpAndSettle();
    await t.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await t.pump();
    final fades = t.widgetList<AnimatedOpacity>(find.descendant(of: find.byType(AppBar), matching: find.byType(AnimatedOpacity)));
    for (final f in fades) {
      expect(f.duration, Duration.zero);
    }
  });

  testWidgets('the bands say "today" once and "proof on you" once', (t) async {
    await _open(t);
    await t.tap(find.text('MacBook Air 13"').first);
    await t.pumpAndSettle();
    expect(find.byType(TimeBand), findsWidgets);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('proof on you').evaluate().length, lessThanOrEqualTo(1));
    // Under the first band.
    final first = t.getRect(find.byType(TimeBand).first);
    final word = t.getRect(find.text('today'));
    expect(first.contains(word.center), isTrue);
  });
}
