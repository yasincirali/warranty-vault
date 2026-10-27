import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/documents.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

Future<MemoryVaultStore> _open(WidgetTester t, {double textScale = 1}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(demoVault());
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(store),
      ruleSetProvider.overrideWith((_) async => _rules),
      docPickerProvider.overrideWithValue((_) async => (bytes: Uint8List.fromList([1, 2, 3]), extension: 'jpg')),
    ],
    child: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(textScale)), child: const WarrantyVaultApp()),
  ));
  await t.pumpAndSettle();
  await t.ensureVisible(find.text('MacBook Air 13"').first);
  await t.pumpAndSettle();
  await t.tap(find.text('MacBook Air 13"').first);
  await t.pumpAndSettle();
  await t.tap(find.text("Something's wrong"));
  await t.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('step 1 of the claim is done in the flow: the photo joins the papers', (t) async {
    final store = await _open(t);
    String id() => store.current.items.firstWhere((i) => i.name == 'MacBook Air 13"').id;
    final before = store.current.items.firstWhere((i) => i.id == id()).documents.length;
    expect(find.text('1 photo added'), findsNothing);

    await t.ensureVisible(find.text('Add a photo of the problem'));
    await t.tap(find.text('Add a photo of the problem'));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.text('Take a photo'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pumpAndSettle();

    final docs = store.current.items.firstWhere((i) => i.id == id()).documents;
    expect(docs.length, before + 1);
    expect(docs.last.kind, DocKind.other);
    expect(find.text('1 photo added'), findsOneWidget, reason: 'done is said in words');
    expect(find.byType(SnackBar), findsNothing, reason: 'the row already says it');
  });

  testWidgets('the claim flow fits at 3.1x text', (t) async {
    await _open(t, textScale: 3.1);
    await t.scrollUntilVisible(find.text('Add a photo of the problem'), 200, scrollable: find.byType(Scrollable).last);
    expect(t.takeException(), isNull);
  });
}
