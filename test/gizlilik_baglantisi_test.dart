import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/features/settings/settings_screen.dart';
import 'package:warranty_vault/rights/rule_set.dart';

// App Store 5.1.1(i): the privacy policy is reachable inside the app, and
// the link points at the same files the store listing names.
void main() {
  test('each language links to a policy file that exists in legal/', () {
    for (final code in ['tr', 'en', 'de']) {
      final url = privacyPolicyUrl(code);
      final file = url.split('/blob/main/').last;
      expect(File(file).existsSync(), isTrue, reason: url);
    }
    expect(privacyPolicyUrl('tr'), endsWith('gizlilik.md'));
    expect(privacyPolicyUrl('en'), endsWith('privacy.md'));
  });

  test('the store listings name the same URLs', () {
    expect(File('store_listing/tr/metin.md').readAsStringSync(), contains(privacyPolicyUrl('tr')));
    expect(File('store_listing/en/text.md').readAsStringSync(), contains(privacyPolicyUrl('en')));
  });

  testWidgets('Settings › About shows the link as a 44 pt link row, and the version', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault())),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore({'language': 'tr'})),
        ruleSetProvider.overrideWith((_) async => rules),
        appVersionProvider.overrideWith((_) async => (version: '1.0.4', build: '31')),
      ],
      child: const WarrantyVaultApp(),
    ));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.settings_outlined));
    await t.pumpAndSettle();
    final row = find.text('Gizlilik politikası');
    await t.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    expect(row, findsOneWidget);
    final tap = find.ancestor(of: row, matching: find.byType(InkWell));
    expect(t.getSize(tap).height, greaterThanOrEqualTo(44));
    expect(t.getSemantics(row).flagsCollection.isLink, isTrue);
    // The version line under it, for support and testers.
    await t.scrollUntilVisible(find.text('Sürüm 1.0.4 (31)'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Sürüm 1.0.4 (31)'), findsOneWidget);
  });
}
