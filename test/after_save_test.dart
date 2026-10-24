import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/app.dart';
import 'package:warranty_vault/features/capture/add_item_screen.dart';
import 'package:warranty_vault/features/capture/after_save.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/features/items/providers.dart';
import 'package:warranty_vault/features/items/ui/documents.dart';
import 'package:warranty_vault/features/reminders/reminder_plan.dart';
import 'package:warranty_vault/features/reminders/reminders.dart';
import 'package:warranty_vault/features/review/review_prompt.dart';
import 'package:warranty_vault/features/settings/settings.dart';
import 'package:warranty_vault/l10n/generated/app_localizations.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());

class _Scheduler implements ReminderScheduler {
  _Scheduler({this.on = true});
  bool on;
  int asked = 0, settingsOpened = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return on;
  }

  @override
  Future<bool?> enabled() async => on;

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> replace(List<PlannedReminder> plan, AppLocalizations l) async {}

  @override
  Future<String?> launchItem() async => null;

  @override
  Stream<String> get taps => const Stream.empty();
}

Future<(MemoryVaultStore, MemorySettingsStore)> _open(
  WidgetTester t,
  _Scheduler scheduler, {
  Map<String, String>? saved,
  Vault? vault,
  double textScale = 1,
}) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final store = MemoryVaultStore(vault ?? demoVault());
  // Germany: verified rules, so a new product has dates ahead to remind of.
  final settings = MemorySettingsStore({'region': 'DE', ...?saved});
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(settings),
        ruleSetProvider.overrideWith((_) async => _rules),
        photoPickerProvider.overrideWithValue((_) async => null),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        docPickerProvider.overrideWithValue((_) async => (bytes: Uint8List.fromList([1, 2, 3]), extension: 'jpg')),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(textScale)),
        child: const WarrantyVaultApp(),
      ),
    ),
  );
  await t.pumpAndSettle();
  return (store, settings);
}

Future<void> _addKettle(WidgetTester t) async {
  await t.tap(find.text('Add a product'));
  await t.pumpAndSettle();
  await t.enterText(find.widgetWithText(TextField, 'Product'), 'Kettle');
  await t.pump();
  await t.tap(find.text('Put it on the shelf'));
  await t.pumpAndSettle();
  await t.pump(afterSaveSettle);
  await t.pumpAndSettle();
}

Item _item({bool sample = false, bool receipt = false}) => Item(
  id: 'x',
  name: 'x',
  category: ItemCategory.other,
  store: '',
  sample: sample,
  documents: [if (receipt) ItemDoc(path: 'r.jpg', kind: DocKind.receipt, added: DateTime.utc(2026, 10, 1))],
  purchase: Purchase(
    date: DateTime.utc(2026, 10, 1),
    region: 'DE',
    channel: SalesChannel.store,
    manufacturer: const ManufacturerWarranty.none(),
  ),
);

void main() {
  group('the rules', () {
    test('the receipt is asked for only when missing, never for a sample, and not after three "later"s', () {
      expect(shouldAskReceipt(item: _item(), laters: 0), isTrue);
      expect(shouldAskReceipt(item: _item(receipt: true), laters: 0), isFalse);
      expect(shouldAskReceipt(item: _item(sample: true), laters: 0), isFalse);
      expect(shouldAskReceipt(item: _item(), laters: receiptAskLimit), isFalse);
    });

    test(
      'notifications: only with a reminder ahead, never twice after the system prompt, not after two "not now"s',
      () {
        bool ask({bool on = true, bool asked = false, int notNows = 0, bool has = true}) =>
            shouldAskNotify(remindersOn: on, askedBefore: asked, notNows: notNows, hasReminder: has);
        expect(ask(), isTrue);
        expect(ask(has: false), isFalse);
        expect(ask(on: false), isFalse);
        expect(ask(asked: true), isFalse);
        expect(ask(notNows: notifyAskLimit), isFalse);
      },
    );
  });

  testWidgets('after a save: its receipt, then our question, then the system prompt', (t) async {
    final scheduler = _Scheduler();
    final (store, settings) = await _open(t, scheduler);
    await _addKettle(t);

    expect(find.text('Add its receipt too?'), findsOneWidget);
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    final kettle = store.current.items.firstWhere((i) => i.name == 'Kettle');
    expect(kettle.receipt, isNotNull);

    expect(find.text('Remind you before it ends?'), findsOneWidget);
    expect(find.textContaining('First one for this product:'), findsOneWidget);
    expect(scheduler.asked, 0, reason: 'never the system prompt before our own question');
    await t.tap(find.text('Yes, remind me'));
    await t.pumpAndSettle();
    expect(scheduler.asked, 1);
    expect(settings.read(remindersAskedKey), '1');
    expect(afterSaveBusy.value, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('both questions fit at the largest text size (3.1×)', (t) async {
    await _open(t, _Scheduler(), textScale: 3.1);
    // The add form has its own 3.1× test; straight to what follows a save.
    final c = ProviderScope.containerOf(t.element(find.byType(WarrantyVaultApp)));
    final id = await c.read(vaultProvider.notifier).add(_item());
    unawaited(afterSave(t.state<NavigatorState>(find.byType(Navigator).first), c, id));
    await t.pump(afterSaveSettle);
    await t.pumpAndSettle();
    expect(find.text('Add its receipt too?'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.text('Later'), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Later'));
    await t.pumpAndSettle();
    expect(find.text('Remind you before it ends?'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('"later" and "not now" are one tap each and counted', (t) async {
    final scheduler = _Scheduler();
    final (_, settings) = await _open(t, scheduler);
    await _addKettle(t);
    await t.tap(find.text('Later'));
    await t.pumpAndSettle();
    expect(settings.read(receiptLaterKey), '1');
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    expect(settings.read(notifyNotNowKey), '1');
    expect(scheduler.asked, 0);
    expect(settings.read(remindersAskedKey), isNull);
  });

  testWidgets('once the prompt was answered, a new product asks only for its receipt', (t) async {
    final scheduler = _Scheduler();
    await _open(t, scheduler, saved: {remindersAskedKey: '1'});
    await _addKettle(t);
    await t.tap(find.text('Later'));
    await t.pumpAndSettle();
    expect(find.text('Remind you before it ends?'), findsNothing);
    expect(scheduler.asked, 0);
  });

  group('notifications off', () {
    Future<void> toSettingsRow(WidgetTester t, String text) async {
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text(text), 200, scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
    }

    testWidgets('turned off in the phone: Settings says so and opens the phone\'s settings', (t) async {
      final scheduler = _Scheduler(on: false);
      await _open(t, scheduler, saved: {remindersAskedKey: '1'});
      await toSettingsRow(t, "Notifications are off in the phone's settings. Reminders won't arrive.");
      final button = find.widgetWithText(TextButton, 'Open settings');
      expect(t.getSize(button).height, greaterThanOrEqualTo(44));
      await t.tap(button);
      expect(scheduler.settingsOpened, 1);
    });

    testWidgets('never asked (a restored backup): Settings offers to allow, and the line goes once allowed', (t) async {
      final scheduler = _Scheduler();
      final (_, settings) = await _open(t, scheduler);
      await toSettingsRow(t, "Notifications aren't allowed yet. Reminders won't arrive.");
      await t.tap(find.widgetWithText(TextButton, 'Allow'));
      await t.pumpAndSettle();
      expect(scheduler.asked, 1);
      expect(settings.read(remindersAskedKey), '1');
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('allowed: no line anywhere', (t) async {
      await _open(t, _Scheduler(), saved: {remindersAskedKey: '1'});
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });

    testWidgets('a product page with dates ahead says its reminders will not arrive', (t) async {
      await _open(t, _Scheduler(on: false), saved: {remindersAskedKey: '1'});
      await t.scrollUntilVisible(find.text('MacBook Air 13"'), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('MacBook Air 13"').first);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text("Notifications are off, so this product's reminders won't arrive."),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Open settings'), findsOneWidget);
    });
  });

  testWidgets('the rating ask waits for the after-save steps instead of being lost', (t) async {
    final store = MemorySettingsStore();
    var calls = 0, held = true;
    final prompt = ReviewPrompt(
      store: () => store,
      requester: () => _Requester(() => calls++),
      atHome: () => true,
      held: () => held,
    );
    Vault v(int n) => Vault(
      items: [for (var i = 0; i < n; i++) _item().copyWith(id: 'i$i')],
      shelves: const [],
    );
    prompt.onVault(v(2), v(3));
    await t.pump(ReviewPrompt.settle);
    expect(calls, 0);
    held = false;
    prompt.resume();
    await t.pump();
    expect(calls, 1);
    expect(store.read(ReviewPrompt.askedKey), '1');
    prompt.dispose();
  });
}

class _Requester implements ReviewRequester {
  _Requester(this.onAsk);
  final void Function() onAsk;
  @override
  Future<void> request() async => onAsk();
}
