import 'rule_set.dart';

enum SalesChannel { store, online }

enum ProtectionKind {
  /// Distance-selling withdrawal (14 days in EU/UK/TR) or a store's own
  /// return policy.
  returnWindow,

  /// UK only: 30-day short-term right to reject faulty goods.
  shortTermReject,
  manufacturer,
  extended,

  /// The seller's statutory liability (EU "legal guarantee", UK CRA, TR 6502).
  legal,
}

enum ProtectionStatus { active, ended, unverified }

class Protection {
  const Protection({
    required this.kind,
    required this.start,
    required this.end,
    required this.status,
    this.presumptionEnd,
    this.sources = const [],
  });

  final ProtectionKind kind;
  final DateTime start;

  /// Null = no fixed end (lifetime warranty, Australian "reasonable time").
  final DateTime? end;
  final ProtectionStatus status;

  /// Legal right only: until this date a defect is presumed to have existed
  /// at delivery, so the seller must prove otherwise ("burden on seller").
  final DateTime? presumptionEnd;
  final List<String> sources;

  int? daysLeft(DateTime today) =>
      end == null ? null : dateOnly(end!).difference(dateOnly(today)).inDays;

  bool sellerBearsProofOn(DateTime day) =>
      presumptionEnd != null && !dateOnly(day).isAfter(presumptionEnd!);
}

class ManufacturerWarranty {
  const ManufacturerWarranty.months(int this.months) : lifetime = false;
  const ManufacturerWarranty.lifetime()
      : months = null,
        lifetime = true;
  const ManufacturerWarranty.none()
      : months = 0,
        lifetime = false;

  final int? months;
  final bool lifetime;
}

class Purchase {
  const Purchase({
    required this.date,
    required this.region,
    required this.channel,
    this.manufacturer = const ManufacturerWarranty.none(),
    this.extendedUntil,
    this.storeReturnDays,
    this.repairs = const [],
  });

  /// Delivery date; statutory periods run from delivery. The app uses the
  /// purchase date until the user enters a separate delivery date.
  final DateTime date;
  final String region;
  final SalesChannel channel;
  final ManufacturerWarranty manufacturer;
  final DateTime? extendedUntil;

  /// The store's own goodwill return policy, if the user knows it.
  final int? storeReturnDays;

  /// Dates of completed repairs under the legal right.
  final List<DateTime> repairs;
}

/// Pure calculation: purchase + rules + today → the list of protections.
///
/// Kept free of Flutter and I/O so the same logic can be tested exhaustively
/// and ported 1:1 to the server and the web tool.
class RightsEngine {
  const RightsEngine(this.rules);

  final RuleSet rules;

  List<Protection> evaluate(Purchase p, DateTime today) {
    final rule = rules[p.region];
    final start = dateOnly(p.date);
    final now = dateOnly(today);
    final out = <Protection>[];

    ProtectionStatus statusFor(DateTime? end, {bool verified = true}) {
      if (!verified) return ProtectionStatus.unverified;
      if (end == null) return ProtectionStatus.active;
      return now.isAfter(end) ? ProtectionStatus.ended : ProtectionStatus.active;
    }

    // Return window: statutory withdrawal for online purchases, otherwise the
    // store's own policy. Withdrawal is listed even for unverified regions
    // because the 14-day rule is the same across EU/UK/TR; marked unverified.
    final withdrawal = rule?.distanceWithdrawalDays;
    final returnDays = p.channel == SalesChannel.online && withdrawal != null
        ? withdrawal
        : p.storeReturnDays;
    if (returnDays != null && returnDays > 0) {
      final end = start.add(Duration(days: returnDays));
      final statutory = p.channel == SalesChannel.online && withdrawal != null;
      out.add(Protection(
        kind: ProtectionKind.returnWindow,
        start: start,
        end: end,
        status: statusFor(end, verified: !statutory || rule!.verified),
        sources: statutory ? rule!.sources : const [],
      ));
    }

    if (rule?.shortTermRejectDays != null) {
      final end = start.add(Duration(days: rule!.shortTermRejectDays!));
      out.add(Protection(
        kind: ProtectionKind.shortTermReject,
        start: start,
        end: end,
        status: statusFor(end),
        sources: rule.sources,
      ));
    }

    final m = p.manufacturer;
    if (m.lifetime || (m.months ?? 0) > 0) {
      final end = m.lifetime ? null : addMonths(start, m.months!);
      out.add(Protection(
        kind: ProtectionKind.manufacturer,
        start: start,
        end: end,
        status: statusFor(end),
      ));
    }

    if (p.extendedUntil != null) {
      final end = dateOnly(p.extendedUntil!);
      out.add(Protection(
        kind: ProtectionKind.extended,
        start: start,
        end: end,
        status: statusFor(end),
      ));
    }

    if (rule != null && (rule.legalMonths != null || rule.reasonableDuration)) {
      DateTime? end =
          rule.legalMonths == null ? null : addMonths(start, rule.legalMonths!);
      if (end != null && _repairExtends(rule, start)) {
        for (final r in p.repairs) {
          if (!dateOnly(r).isAfter(end!)) {
            end = addMonths(end, rule.repairExtensionMonths!);
          }
        }
      }
      out.add(Protection(
        kind: ProtectionKind.legal,
        start: start,
        end: end,
        status: statusFor(end, verified: rule.verified),
        presumptionEnd: rule.presumptionMonths == null
            ? null
            : addMonths(start, rule.presumptionMonths!),
        sources: rule.sources,
      ));
    }

    out.sort((a, b) => _order(a, now).compareTo(_order(b, now)));
    return out;
  }

  bool _repairExtends(RegionRule rule, DateTime start) =>
      rule.repairExtensionVerified &&
      rule.repairExtensionMonths != null &&
      rule.repairExtensionFrom != null &&
      !start.isBefore(rule.repairExtensionFrom!);

  /// Active first, soonest end first; then unverified; then ended.
  int _order(Protection p, DateTime now) {
    const far = 1 << 30;
    switch (p.status) {
      case ProtectionStatus.active:
        return p.daysLeft(now) ?? far ~/ 2;
      case ProtectionStatus.unverified:
        return far;
      case ProtectionStatus.ended:
        return far + 1;
    }
  }
}

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Calendar month arithmetic; clamps to the last day (31 Jan + 1 = 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12;
  final mo = total % 12 + 1;
  final lastDay = DateTime.utc(y, mo + 1, 0).day;
  return DateTime.utc(y, mo, d.day > lastDay ? lastDay : d.day);
}
