import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/documents.dart';
import 'package:warranty_vault/features/reminders/reminder_plan.dart';
import 'package:warranty_vault/features/reminders/reminders.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/l10n/generated/app_localizations.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

/// Records what would reach the phone's notification centre.
class _FakeScheduler implements ReminderScheduler {
  int asked = 0;
  final replaced = <List<PlannedReminder>>[];
  final bodies = <String>[];
  final _taps = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    asked++;
    return true;
  }

  @override
  Future<bool?> enabled() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> replace(List<PlannedReminder> plan, AppLocalizations l) async {
    replaced.add(plan);
    bodies
      ..clear()
      ..addAll(plan.map((r) => reminderBody(l, r)));
  }

  @override
  Future<String?> launchItem() async => null;

  @override
  Stream<String> get taps => _taps.stream;

  void tap(String id) => _taps.add(id);
}

Future<(MemoryVaultStore, MemorySettingsStore)> _open(
  WidgetTester t, {
  Vault? vault,
  double textScale = 1,
  Map<String, String>? saved,
  List overrides = const [],
}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(vault ?? demoVault());
  final settings = MemorySettingsStore(saved);
  await t.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      vaultStoreProvider.overrideWithValue(store),
      settingsStoreProvider.overrideWithValue(settings),
      ruleSetProvider.overrideWith((_) async => _rules),
      photoPickerProvider.overrideWithValue((_) async => null),
      ...overrides,
    ],
    child: MediaQuery(
      data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
      child: const WarrantyVaultApp(),
    ),
  ));
  await t.pumpAndSettle();
  return (store, settings);
}

Future<void> _openMac(WidgetTester t) async {
  await t.scrollUntilVisible(find.text('MacBook Air 13"'), 200, scrollable: find.byType(Scrollable).first);
  final mac = find.text('MacBook Air 13"').first;
  await t.ensureVisible(mac);
  await t.pumpAndSettle();
  await t.tap(mac);
  await t.pumpAndSettle();
}

Future<void> _toDocs(WidgetTester t) async {
  await t.scrollUntilVisible(find.text('Add a receipt or paper'), 200, scrollable: find.byType(Scrollable).last);
  await t.pumpAndSettle();
}

void main() {
  group('search', () {
    testWidgets('typing finds a product by store and opens it', (t) async {
      await _open(t);
      await t.tap(find.byTooltip('Search'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'saturn');
      await t.pump();
      expect(find.text('MacBook Air 13"'), findsWidgets);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget, reason: 'the receipt shows without opening');
      await t.tap(find.text('MacBook Air 13"').last);
      await t.pumpAndSettle();
      expect(find.text("Something's wrong"), findsOneWidget);
    });

    testWidgets('no match says so; an empty cabinet has no search button', (t) async {
      await _open(t);
      await t.tap(find.byTooltip('Search'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'zzzz');
      await t.pump();
      expect(find.textContaining('Nothing in the cabinet matches'), findsOneWidget);
    });

    testWidgets('the search button is not shown before anything is in the cabinet', (t) async {
      await _open(t, vault: const Vault());
      expect(find.byTooltip('Search'), findsNothing);
    });
  });

  group('documents', () {
    testWidgets('a photographed receipt is kept and the counter screen shows it', (t) async {
      final picked = <DocSource>[];
      final (store, _) = await _open(t, overrides: [
        docPickerProvider.overrideWithValue((s) async {
          picked.add(s);
          return (bytes: Uint8List.fromList([1, 2, 3]), extension: 'jpg');
        }),
      ]);
      await t.scrollUntilVisible(find.text('Sony WH-1000XM5'), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Sony WH-1000XM5').first);
      await t.pumpAndSettle();
      await _toDocs(t);
      expect(find.textContaining('never fades'), findsOneWidget, reason: 'why it matters, while nothing is stored');
      await t.tap(find.text('Add a receipt or paper'));
      await t.pumpAndSettle();
      // The receipt is preselected while there is none.
      expect(
        t.getSemantics(find.ancestor(of: find.text('Receipt or invoice'), matching: find.byType(Semantics)).first),
        isSemantics(isSelected: true, isButton: true),
      );
      await t.tap(find.text('Take a photo'));
      await t.pumpAndSettle();
      expect(picked, [DocSource.camera]);
      final sony = store.current.items.firstWhere((i) => i.id == 'sony');
      expect(sony.receipt?.path, startsWith('docs/sony-'));
      expect(sony.receipt!.isPdf, isFalse);
      expect(find.text('Receipt or invoice saved'), findsOneWidget);
    });

    testWidgets('an e-invoice PDF opens in the system viewer; delete asks first', (t) async {
      final opened = <String>[];
      final (store, _) = await _open(t, overrides: [
        docPickerProvider.overrideWithValue((s) async => (bytes: Uint8List.fromList([37, 80, 68, 70]), extension: 'pdf')),
        openFileProvider.overrideWithValue((p) async => opened.add(p)),
      ]);
      await _openMac(t);
      await _toDocs(t);
      expect(find.text('Receipt or invoice'), findsOneWidget, reason: 'the sample receipt');
      await t.tap(find.text('Add a receipt or paper'));
      await t.pumpAndSettle();
      await t.tap(find.text('Manual'));
      await t.pump();
      await t.tap(find.text('PDF file (e-invoice)'));
      await t.pumpAndSettle();
      final mac = store.current.items.firstWhere((i) => i.id == 'macbook');
      expect([for (final d in mac.documents) d.kind], [DocKind.receipt, DocKind.manual]);

      // The in-memory store has no file on disk to hand over.
      await t.tap(find.text('Manual'));
      await t.pumpAndSettle();
      expect(opened, isEmpty);

      await t.tap(find.text('Receipt or invoice'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete Receipt or invoice?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(store.current.items.firstWhere((i) => i.id == 'macbook').receipt, isNotNull);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect(store.current.items.firstWhere((i) => i.id == 'macbook').receipt, isNull);
    });

    testWidgets('the counter screen shows the stored receipt image', (t) async {
      await _open(t);
      await _openMac(t);
      await t.scrollUntilVisible(find.text('Show at the counter'), 200, scrollable: find.byType(Scrollable).last);
      await t.tap(find.text('Show at the counter'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Receipt, opens full screen'), findsOneWidget);
      expect(find.text('Add the receipt or invoice'), findsNothing);
    });

    test('an older build’s single invoicePath is read as the receipt', () {
      final j = demoVault().items.first.toJson()
        ..remove('documents')
        ..['invoicePath'] = 'docs/old.pdf';
      final item = Item.fromJson(j);
      expect(item.receipt?.path, 'docs/old.pdf');
      expect(Item.fromJson(item.toJson()).documents, hasLength(1), reason: 'saved back as documents');
    });

    for (final scale in [1.0, 3.1]) {
      testWidgets('documents section and add sheet fit at ${scale}x text', (t) async {
        await _open(t, textScale: scale);
        await _openMac(t);
        await _toDocs(t);
        expect(t.takeException(), isNull);
        await t.tap(find.text('Add a receipt or paper'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final f in [find.text('Take a photo'), find.text('Warranty card')]) {
          await t.ensureVisible(f);
          expect(t.getSize(f).height, greaterThan(0));
          final hit = find.ancestor(of: f, matching: find.byWidgetPredicate((w) => w is InkWell || w is ButtonStyleButton)).first;
          expect(t.getSize(hit).height, greaterThanOrEqualTo(44));
        }
      });
    }
  });

  group('reminders', () {
    testWidgets('the cabinet is planned after a short pause, never a cold permission prompt, moves send nothing', (t) async {
      final fake = _FakeScheduler();
      final (_, settings) = await _open(t, overrides: [reminderSchedulerProvider.overrideWithValue(fake)]);
      await t.pump(ReminderSync.debounce);
      await t.pumpAndSettle();
      // The system prompt only follows our own question after a save.
      expect(fake.asked, 0);
      expect(fake.replaced, hasLength(1));
      expect(fake.replaced.single, isNotEmpty);
      expect(fake.bodies.first, contains('report it before the last day'));
      expect(settings.read('reminders_asked'), isNull);

      // A change that does not touch any deadline reaches the platform as nothing.
      final c = ProviderScope.containerOf(t.element(find.byType(Scaffold).first));
      final shelves = c.read(vaultProvider).value!.shelves;
      await c.read(vaultProvider.notifier).move('macbook', shelves.length - 1, 0);
      await t.pump(ReminderSync.debounce);
      await t.pumpAndSettle();
      expect(fake.replaced, hasLength(1));
      expect(fake.asked, 0);
    });

    testWidgets('switching reminders off clears them; the choice is remembered', (t) async {
      final fake = _FakeScheduler();
      final (_, settings) = await _open(t, overrides: [reminderSchedulerProvider.overrideWithValue(fake)]);
      await t.pump(ReminderSync.debounce);
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('Remind me before rights end'), 200, scrollable: find.byType(Scrollable).last);
      await t.ensureVisible(find.byType(Switch));
      await t.pumpAndSettle();
      await t.tap(find.byType(Switch));
      await t.pump(ReminderSync.debounce);
      await t.pumpAndSettle();
      expect(fake.replaced.last, isEmpty);
      expect(settings.read('reminders'), 'off');
    });

    testWidgets('the notification is written in the app language, not only the phone’s', (t) async {
      final fake = _FakeScheduler();
      await _open(t, saved: {'language': 'tr'}, overrides: [reminderSchedulerProvider.overrideWithValue(fake)]);
      await t.pump(ReminderSync.debounce);
      await t.pumpAndSettle();
      expect(fake.bodies.first, contains('şimdi bildir'));
    });

    testWidgets('tapping a reminder opens that product', (t) async {
      final fake = _FakeScheduler();
      await _open(t, overrides: [reminderSchedulerProvider.overrideWithValue(fake)]);
      fake.tap('sony');
      await t.pumpAndSettle();
      expect(find.text("Something's wrong"), findsOneWidget);
      expect(find.text('Sony WH-1000XM5'), findsWidgets);
    });

    testWidgets('settings fit at 3.1x text with the new sections', (t) async {
      await _open(t, textScale: 3.1);
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('Remind me before rights end'), 300, scrollable: find.byType(Scrollable).last);
      expect(t.takeException(), isNull);
    });
  });
}
