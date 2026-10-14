import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/rights/advice.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

void main() {
  // The real rules file, not a fixture: a rule change must keep these green.
  final rules =
      RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());
  final engine = RightsEngine(rules);
  DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

  Protection find(List<Protection> ps, ProtectionKind k) =>
      ps.firstWhere((p) => p.kind == k);

  group('rules file', () {
    test('Germany inherits the EU baseline', () {
      final de = rules['DE']!;
      expect(de.legalMonths, 24);
      expect(de.presumptionMonths, 12);
      expect(de.distanceWithdrawalDays, 14);
      expect(de.verified, isTrue);
    });

    test('every verified region cites a source', () {
      for (final r in rules.regions.values.where((r) => r.verified)) {
        expect(r.sources, isNotEmpty, reason: r.code);
      }
    });
  });

  group('addMonths', () {
    test('clamps month ends', () {
      expect(addMonths(d(2024, 1, 31), 1), d(2024, 2, 29));
      expect(addMonths(d(2023, 1, 31), 1), d(2023, 2, 28));
      expect(addMonths(d(2024, 11, 10), 24), d(2026, 11, 10));
    });
  });

  group('Germany: the design example (MacBook, Saturn Berlin)', () {
    final p = Purchase(
      date: d(2024, 11, 10),
      region: 'DE',
      channel: SalesChannel.store,
      manufacturer: const ManufacturerWarranty.months(12),
    );
    final ps = engine.evaluate(p, d(2026, 10, 13));

    test('manufacturer ended, legal right has 28 days left', () {
      expect(find(ps, ProtectionKind.manufacturer).status,
          ProtectionStatus.ended);
      final legal = find(ps, ProtectionKind.legal);
      expect(legal.status, ProtectionStatus.active);
      expect(legal.end, d(2026, 11, 10));
      expect(legal.daysLeft(d(2026, 10, 13)), 28);
    });

    test('burden of proof has moved to the buyer after 12 months', () {
      expect(find(ps, ProtectionKind.legal).sellerBearsProofOn(d(2026, 10, 13)),
          isFalse);
      expect(find(ps, ProtectionKind.legal).sellerBearsProofOn(d(2025, 11, 10)),
          isTrue);
    });

    test('active protections sort first', () {
      expect(ps.first.kind, ProtectionKind.legal);
    });

    test('a defect means: ask the seller to repair', () {
      final a = adviseFor(IssueType.defect, ps, d(2026, 10, 13));
      expect(a.action, AdviceAction.askSellerRepair);
      expect(a.sellerBearsProof, isFalse);
    });

    test('appears in the attention list', () {
      expect(nextDeadline(ps, d(2026, 10, 13))?.kind, ProtectionKind.legal);
      expect(nextDeadline(ps, d(2026, 9, 1)), isNull);
    });
  });

  group('boundaries', () {
    final p = Purchase(
        date: d(2024, 11, 10), region: 'DE', channel: SalesChannel.store);
    test('last day is still active, next day ended', () {
      expect(find(engine.evaluate(p, d(2026, 11, 10)), ProtectionKind.legal)
          .status, ProtectionStatus.active);
      expect(find(engine.evaluate(p, d(2026, 11, 11)), ProtectionKind.legal)
          .status, ProtectionStatus.ended);
    });
  });

  group('online purchase return window', () {
    final p = Purchase(
        date: d(2026, 10, 2), region: 'DE', channel: SalesChannel.online);
    test('14-day withdrawal comes first and wins the advice', () {
      final ps = engine.evaluate(p, d(2026, 10, 12));
      expect(ps.first.kind, ProtectionKind.returnWindow);
      expect(ps.first.daysLeft(d(2026, 10, 12)), 4);
      expect(adviseFor(IssueType.arrivedDamaged, ps, d(2026, 10, 12)).action,
          AdviceAction.returnItem);
    });
    test('store purchase has no statutory return window', () {
      final store = Purchase(
          date: d(2026, 10, 2), region: 'DE', channel: SalesChannel.store);
      expect(engine.evaluate(store, d(2026, 10, 3))
          .where((x) => x.kind == ProtectionKind.returnWindow), isEmpty);
    });
  });

  group('unverified regions never claim a legal right', () {
    test('Türkiye legal right is marked unverified', () {
      final ps = engine.evaluate(
          Purchase(
              date: d(2026, 1, 1),
              region: 'TR',
              channel: SalesChannel.store,
              manufacturer: const ManufacturerWarranty.months(24)),
          d(2026, 10, 13));
      expect(find(ps, ProtectionKind.legal).status,
          ProtectionStatus.unverified);
      expect(adviseFor(IssueType.defect, ps, d(2026, 10, 13)).action,
          AdviceAction.askManufacturer);
    });

    test('no fixed legal period and no warranty → not covered', () {
      final ps = engine.evaluate(
          Purchase(date: d(2026, 1, 1), region: 'US', channel: SalesChannel.store),
          d(2026, 10, 13));
      expect(ps.where((p) => p.kind == ProtectionKind.legal), isEmpty);
      expect(adviseFor(IssueType.defect, ps, d(2026, 10, 13)).action,
          AdviceAction.notCovered);
    });
  });

  group('other rules', () {
    test('UK 30-day short-term right to reject', () {
      final ps = engine.evaluate(
          Purchase(date: d(2026, 10, 1), region: 'GB', channel: SalesChannel.store),
          d(2026, 10, 13));
      expect(find(ps, ProtectionKind.shortTermReject).daysLeft(d(2026, 10, 13)),
          18);
      expect(adviseFor(IssueType.defect, ps, d(2026, 10, 13)).action,
          AdviceAction.rejectGoods);
    });

    test('Australia: no fixed end, active', () {
      final ps = engine.evaluate(
          Purchase(date: d(2020, 1, 1), region: 'AU', channel: SalesChannel.store),
          d(2026, 10, 13));
      final legal = find(ps, ProtectionKind.legal);
      expect(legal.end, isNull);
      expect(legal.status, ProtectionStatus.active);
    });

    test('lifetime manufacturer warranty never ends', () {
      final ps = engine.evaluate(
          Purchase(
              date: d(2001, 1, 1),
              region: 'DE',
              channel: SalesChannel.store,
              manufacturer: const ManufacturerWarranty.lifetime()),
          d(2026, 10, 13));
      expect(find(ps, ProtectionKind.manufacturer).status,
          ProtectionStatus.active);
    });

    test('repair extension stays off until verified', () {
      final ps = engine.evaluate(
          Purchase(
              date: d(2026, 8, 1),
              region: 'DE',
              channel: SalesChannel.store,
              repairs: [d(2027, 1, 1)]),
          d(2027, 2, 1));
      expect(find(ps, ProtectionKind.legal).end, d(2028, 8, 1));
    });

    test('loss is never a guarantee case', () {
      expect(adviseFor(IssueType.lostOrStolen, const [], d(2026, 1, 1)).action,
          AdviceAction.insurance);
    });
  });
}
