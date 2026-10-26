import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/cabinet/cabinet_view.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/rights/rule_set.dart';

// Asset loading is real I/O and never settles under fake async; the same
// file is read synchronously instead.
final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// The design's reference day: MacBook has 28 days of legal right left,
/// the Sony bought online on 2 Oct has 3 days of its return window.
Widget app({double textScale = 1, VaultStore? store, bool dark = false}) => ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(store ?? MemoryVaultStore(demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          platformBrightness: dark ? Brightness.dark : Brightness.light,
        ),
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
      // Marked as samples so the "Remove samples" line is on screen too.
      final d = demoVault();
      final samples = Vault(items: [for (final i in d.items) i.copyWith(sample: true)], shelves: d.shelves);
      await t.pumpWidget(app(textScale: scale, store: MemoryVaultStore(samples)));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('Remove samples'), 200, scrollable: find.byType(Scrollable).first);
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

  for (final scale in [1.0, 3.1]) {
    testWidgets('detail, counter and problem flow fit at ${scale}x text, dark', (t) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(app(textScale: scale, dark: true));
      await t.pumpAndSettle();
      // At 3.1× the header (title + settings button) pushes the list below
      // the lazily built area, so scroll to it instead of assuming it exists.
      await t.scrollUntilVisible(find.text('MacBook Air 13"'), 200, scrollable: find.byType(Scrollable).first);
      final mac = find.text('MacBook Air 13"').first;
      await t.ensureVisible(mac);
      await t.pumpAndSettle();
      await t.tap(mac);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(find.text('days left'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('days left'), findsOneWidget);

      // .last: the home list stays mounted under the pushed route.
      await t.scrollUntilVisible(find.text('Show at the counter'), 200,
          scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
      await t.tap(find.text('Show at the counter'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('C02FK3XJQ6L4'), findsOneWidget);
    });
  }

  testWidgets('first run shows the empty cabinet and a sample cabinet', (t) async {
    final store = MemoryVaultStore();
    await t.pumpWidget(app(store: store));
    await t.pumpAndSettle();
    expect(find.byType(EmptyCabinet), findsOneWidget);
    await t.ensureVisible(find.text('Try the sample shelves'));
    await t.pumpAndSettle();
    await t.tap(find.text('Try the sample shelves'));
    await t.pumpAndSettle();
    expect(store.current.active, hasLength(6));
    expect(find.text('Needs attention · 2'), findsOneWidget);

    // Samples are marked, say so in one line and leave in one tap, shelves
    // included: the first-run page is back, not three empty named shelves.
    expect(store.current.items.every((i) => i.sample), isTrue);
    expect(find.text('These are sample products. They send no reminders.'), findsOneWidget);
    await t.tap(find.text('Remove samples'));
    await t.pumpAndSettle();
    expect(store.current.items, isEmpty);
    expect(store.current.disposed, isEmpty);
    expect(find.text('Try the sample shelves'), findsOneWidget);
  });

  testWidgets('time rule appears instantly with reduce motion', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: const MediaQuery(data: MediaQueryData(disableAnimations: true), child: WarrantyVaultApp()),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('MacBook Air 13"').first);
    await t.pump();
    await t.pump();
    // No frames scheduled once the route settles: the rule did not animate.
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('of the period has passed')), findsWidgets);
  });
}
