import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/review/review_prompt.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Item _own(String id) => Item(
      id: id,
      name: id,
      store: '',
      purchase: Purchase(date: DateTime.utc(2026, 10, 1), region: 'DE', channel: SalesChannel.store),
    );

Vault _vault(int own, {int samples = 0}) => Vault(items: [
      for (var i = 0; i < own; i++) _own('o$i'),
      for (final s in demoVault().items.take(samples)) s.copyWith(sample: true),
    ]);

class _Recorder implements ReviewRequester {
  int calls = 0;
  @override
  Future<void> request() async => calls++;
}

void main() {
  group('when to ask', () {
    test('the third own product asks, the second does not', () {
      expect(shouldAskForReview(before: _vault(1), after: _vault(2), asked: false), isFalse);
      expect(shouldAskForReview(before: _vault(2), after: _vault(3), asked: false), isTrue);
    });

    test('samples never count', () {
      expect(shouldAskForReview(before: _vault(2), after: _vault(2, samples: 6), asked: false), isFalse);
      expect(shouldAskForReview(before: _vault(0, samples: 6), after: _vault(1, samples: 6), asked: false), isFalse);
    });

    test('only once, never on app start, never on a restored backup', () {
      expect(shouldAskForReview(before: _vault(2), after: _vault(3), asked: true), isFalse);
      expect(shouldAskForReview(before: null, after: _vault(10), asked: false), isFalse);
      expect(shouldAskForReview(before: _vault(0), after: _vault(10), asked: false), isFalse);
      // An existing tester with ten: asked after the eleventh.
      expect(shouldAskForReview(before: _vault(10), after: _vault(11), asked: false), isTrue);
    });
  });

  Future<(ProviderContainer, _Recorder, MemorySettingsStore)> open(WidgetTester t) async {
    final rec = _Recorder();
    final settings = MemorySettingsStore();
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(_vault(2))),
        settingsStoreProvider.overrideWithValue(settings),
        ruleSetProvider.overrideWith((_) async => _rules),
        reviewRequesterProvider.overrideWithValue(rec),
      ],
      child: const WarrantyVaultApp(),
    ));
    await t.pumpAndSettle();
    return (ProviderScope.containerOf(t.element(find.byType(WarrantyVaultApp))), rec, settings);
  }

  testWidgets('third own product on the cabinet: the system sheet is asked for once', (t) async {
    final (c, rec, settings) = await open(t);
    await c.read(vaultProvider.notifier).add(_own('third'));
    await t.pump(ReviewPrompt.settle);
    await t.pumpAndSettle();
    expect(rec.calls, 1);
    expect(settings.read(ReviewPrompt.askedKey), '1');

    await c.read(vaultProvider.notifier).add(_own('fourth'));
    await t.pump(ReviewPrompt.settle);
    await t.pumpAndSettle();
    expect(rec.calls, 1);
  });

  testWidgets('not over another screen: a product page open means not now', (t) async {
    final (c, rec, settings) = await open(t);
    await c.read(vaultProvider.notifier).add(_own('third'));
    // The user opened something before the product finished landing.
    await t.tap(find.text('o0').first);
    await t.pump(ReviewPrompt.settle);
    await t.pumpAndSettle();
    expect(find.text("Something's wrong"), findsOneWidget);
    expect(rec.calls, 0);
    expect(settings.read(ReviewPrompt.askedKey), isNull);
  });
}
