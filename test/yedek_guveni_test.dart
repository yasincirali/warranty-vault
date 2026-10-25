import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/backup/backup.dart';
import 'package:warranty_vault/features/backup/backup_rows.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/reminders/reminders.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

/// Rafım Ar-Ge 25 Oct (yasin "yap"): Settings answers "and if I lose the
/// phone?" truthfully, and says when the last backup file was made.
final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Item _item(int i, {bool sample = false}) => Item(
  id: 'i$i',
  name: 'Item $i',
  category: ItemCategory.other,
  store: '',
  sample: sample,
  purchase: Purchase(
    date: DateTime.utc(2026, 10, 1),
    region: 'DE',
    channel: SalesChannel.store,
    manufacturer: const ManufacturerWarranty.none(),
  ),
);

Vault _vault(int own, {int samples = 0}) => Vault(
  items: [for (var i = 0; i < own; i++) _item(i), for (var i = 0; i < samples; i++) _item(100 + i, sample: true)],
);

Future<ProviderContainer> _settings(WidgetTester t, Vault v, {Map<String, String>? saved, double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 25)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(v)),
        backupDirProvider.overrideWithValue(Directory.systemTemp),
        settingsStoreProvider.overrideWithValue(
          MemorySettingsStore({'region': 'DE', 'language': 'en', remindersAskedKey: '1', ...?saved}),
        ),
        ruleSetProvider.overrideWith((_) async => _rules),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
        child: const WarrantyVaultApp(),
      ),
    ),
  );
  await t.pumpAndSettle();
  await t.tap(find.byTooltip('Settings'));
  await t.pumpAndSettle();
  return ProviderScope.containerOf(t.element(find.byType(WarrantyVaultApp)));
}

Future<void> _scrollTo(WidgetTester t, Finder f) =>
    t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);

void main() {
  testWidgets('a made backup is shown with its date', (t) async {
    await _settings(t, _vault(3), saved: {lastBackupKey: '2026-10-12T09:00:00.000Z'});
    await _scrollTo(t, find.textContaining('Last backup file:'));
    expect(find.text('Last backup file: Oct 12, 2026'), findsOneWidget);
  });

  testWidgets('ten own products and no backup: the card says so; samples do not count', (t) async {
    await _settings(t, _vault(backupNudgeFrom, samples: 6));
    await _scrollTo(t, find.textContaining('no backup yet'));
    expect(find.textContaining('You have 10 products and no backup yet.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('a small cabinet with no backup is not nagged', (t) async {
    await _settings(t, _vault(backupNudgeFrom - 1, samples: 6));
    await _scrollTo(t, find.text('Back up the cabinet'));
    expect(find.textContaining('no backup yet'), findsNothing);
    expect(find.textContaining('Last backup file'), findsNothing);
  });

  testWidgets('a restored older backup does not move the date back; a newer one does', (t) async {
    final c = await _settings(t, _vault(1));
    final last = c.read(lastBackupProvider.notifier);
    await last.record(DateTime.utc(2026, 10, 20));
    await last.record(DateTime.utc(2026, 9, 1));
    expect(c.read(lastBackupProvider), DateTime.utc(2026, 10, 20));
    await last.record(DateTime.utc(2026, 10, 24));
    expect(c.read(settingsStoreProvider).read(lastBackupKey), '2026-10-24T00:00:00.000Z');
  });

  for (final ios in [true, false]) {
    testWidgets(ios ? 'iOS says the cabinet rides along with the iCloud backup' : 'Android promises no cloud backup', (t) async {
      debugDefaultTargetPlatformOverride = ios ? TargetPlatform.iOS : TargetPlatform.android;
      try {
        await _settings(t, _vault(1));
        await _scrollTo(t, find.textContaining('No account needed.'));
        expect(find.textContaining('iCloud Backup is on'), ios ? findsOneWidget : findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('the status line fits at the largest text size (3.1×)', (t) async {
    await _settings(t, _vault(12), textScale: 3.1);
    await _scrollTo(t, find.textContaining('no backup yet'));
    expect(t.takeException(), isNull);
  });
}
