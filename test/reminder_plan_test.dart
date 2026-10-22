import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/reminders/reminder_plan.dart';
import 'package:warranty_vault/rights/advice.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _engine = RightsEngine(RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync()));

ItemView _view(String id, DateTime bought, DateTime today,
    {String region = 'DE', SalesChannel channel = SalesChannel.online, int warrantyMonths = 24, DateTime? disposed, bool sample = false}) {
  final item = Item(
    id: id,
    sample: sample,
    name: id,
    store: '',
    disposedAt: disposed,
    purchase: Purchase(
      date: bought,
      region: region,
      channel: channel,
      manufacturer: ManufacturerWarranty.months(warrantyMonths),
    ),
  );
  final ps = _engine.evaluate(item.purchase, today);
  return ItemView(item, ps, nextDeadline(ps, today));
}

void main() {
  final today = DateTime(2026, 10, 17, 9);

  test('an online purchase warns 3 days and 1 day before the return window closes, at 10:00', () {
    final v = _view('kettle', DateTime.utc(2026, 10, 10), today);
    final ret = planReminders([v], today).where((r) => r.kind == ProtectionKind.returnWindow).toList();
    final end = v.protections.firstWhere((p) => p.kind == ProtectionKind.returnWindow).end!;
    expect([for (final r in ret) r.daysBefore], [3, 1]);
    expect(ret.first.fireAt, DateTime(end.year, end.month, end.day - 3, reminderHour));
  });

  test('long guarantees warn a month and a week ahead; nothing already past is planned', () {
    final v = _view('tv', DateTime.utc(2024, 11, 20), today, channel: SalesChannel.store);
    final plan = planReminders([v], today);
    expect(plan.every((r) => r.fireAt.isAfter(today)), isTrue);
    final manu = plan.where((r) => r.kind == ProtectionKind.manufacturer && r.reason == ReminderReason.ends);
    expect([for (final r in manu) r.daysBefore], [30, 7]);
  });

  test('the burden-of-proof shift gets its own reminder while the right outlives it', () {
    // DE: legal guarantee 24 months, seller proves for the first 12.
    final v = _view('phone', DateTime.utc(2026, 1, 5), today, channel: SalesChannel.store);
    final proof = planReminders([v], today).where((r) => r.reason == ReminderReason.proofShifts).toList();
    expect(proof, hasLength(1));
    expect(proof.single.daysBefore, proofLeadDays);
  });

  test('thrown-out products get no reminders', () {
    final v = _view('old', DateTime.utc(2026, 10, 10), today, disposed: DateTime.utc(2026, 10, 12));
    expect(planReminders([v], today), isEmpty);
  });

  test('ids are stable across runs and the signature only changes when timing does', () {
    final a = planReminders([_view('x', DateTime.utc(2026, 10, 10), today)], today);
    final b = planReminders([_view('x', DateTime.utc(2026, 10, 10), today)], today);
    expect([for (final r in a) r.id], [for (final r in b) r.id]);
    expect(planSignature(a), planSignature(b));
    final later = planReminders([_view('x', DateTime.utc(2026, 10, 11), today)], today);
    expect(planSignature(later), isNot(planSignature(a)));
    expect(a.map((r) => r.id).toSet(), hasLength(a.length), reason: 'no two reminders share an id');
  });

  test('never more than iOS keeps, soonest first', () {
    final views = [
      for (var i = 0; i < 300; i++) _view('i$i', DateTime.utc(2026, 1, 1).add(Duration(days: i)), today),
    ];
    final plan = planReminders(views, today);
    expect(plan, hasLength(maxPendingReminders));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
    }
  });

  test('performance: planning a 1 000-product cabinet stays well under a frame', () {
    final views = [
      for (var i = 0; i < 1000; i++) _view('i$i', DateTime.utc(2025, 1, 1).add(Duration(days: i % 600)), today),
    ];
    planReminders(views, today); // warm-up
    final sw = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      planReminders(views, today);
    }
    final perRun = sw.elapsedMicroseconds / 10;
    // ignore: avoid_print
    print('planReminders(1000 items): ${(perRun / 1000).toStringAsFixed(2)} ms');
    expect(perRun, lessThan(16000));
  });

  test('sample products never remind: the user does not own them', () {
    final own = _view('kettle', DateTime.utc(2026, 10, 10), today);
    final sample = _view('macbook', DateTime.utc(2026, 10, 10), today, sample: true);
    final plan = planReminders([own, sample], today);
    expect(plan, isNotEmpty);
    expect(plan.every((r) => r.itemId == 'kettle'), isTrue);
  });
}
