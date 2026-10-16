import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';

/// Why a reminder fires: a protection ends, or the months in which the
/// seller has to prove a defect was not there at delivery run out (after
/// that the user must prove it, so it is the moment to report a problem).
enum ReminderReason { ends, proofShifts }

/// One local notification, decided in pure Dart so the rules are tested
/// without a phone and the platform side only receives a finished list.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.kind,
    required this.reason,
    required this.daysBefore,
    required this.fireAt,
  });

  /// Stable across runs (same item, kind, reason, lead time → same id), so
  /// re-planning replaces a reminder instead of stacking a second one.
  final int id;
  final String itemId;
  final String itemName;
  final ProtectionKind kind;
  final ReminderReason reason;
  final int daysBefore;

  /// Local wall-clock time.
  final DateTime fireAt;
}

/// iOS keeps at most 64 pending local notifications per app and silently
/// drops the rest. 48 leaves room and still covers months ahead: the plan
/// is rebuilt on every change and app start, so later ones move up.
const maxPendingReminders = 48;

/// Morning, not midnight: the end date is a whole day, and 10:00 is when
/// a shop or a support line can still be reached that day.
const reminderHour = 10;

/// How far ahead each kind warns. Return windows are 14–30 days long, so
/// a month ahead would fire on the day of purchase; long guarantees get a
/// month to find the receipt and book a repair.
List<int> leadDaysFor(ProtectionKind kind) => switch (kind) {
      ProtectionKind.returnWindow || ProtectionKind.shortTermReject => const [3, 1],
      ProtectionKind.manufacturer || ProtectionKind.extended || ProtectionKind.legal => const [30, 7],
    };

/// The burden of proof shifts once; two weeks is enough to test the thing
/// and report a fault while the seller still has to prove otherwise.
const proofLeadDays = 14;

/// Reminders still ahead of [now], soonest first, capped at
/// [maxPendingReminders]. Runs on every cabinet change, so it stays cheap:
/// candidates are compared as UTC calendar days (plain integers inside
/// DateTime) and only the kept ones get a local wall-clock time, which is
/// the expensive part (a time-zone lookup per value).
List<PlannedReminder> planReminders(Iterable<ItemView> views, DateTime now) {
  final today = DateTime.utc(now.year, now.month, now.day);
  // A reminder for today still fires if 10:00 has not passed yet.
  final first = now.hour < reminderHour ? today : today.add(const Duration(days: 1));
  final out = <_Candidate>[];
  for (final v in views) {
    if (!v.item.active) continue;
    for (final p in v.protections) {
      if (p.status != ProtectionStatus.active) continue;
      if (p.end != null) {
        final end = dateOnly(p.end!);
        for (final lead in leadDaysFor(p.kind)) {
          final day = end.subtract(Duration(days: lead));
          if (!day.isBefore(first)) out.add(_Candidate(v.item, p.kind, ReminderReason.ends, lead, day));
        }
      }
      final shift = p.presumptionEnd;
      // Only while the right itself outlives the shift; otherwise the
      // "ends" reminder already says everything.
      if (shift != null && (p.end == null || p.end!.isAfter(shift))) {
        final day = dateOnly(shift).subtract(const Duration(days: proofLeadDays));
        if (!day.isBefore(first)) out.add(_Candidate(v.item, p.kind, ReminderReason.proofShifts, proofLeadDays, day));
      }
    }
  }
  out.sort(_Candidate.compare);
  return [
    for (final c in out.take(maxPendingReminders))
      PlannedReminder(
        id: _stableId('${c.item.id}|${c.kind.name}|${c.reason.name}|${c.lead}'),
        itemId: c.item.id,
        itemName: c.item.name,
        kind: c.kind,
        reason: c.reason,
        daysBefore: c.lead,
        fireAt: DateTime(c.day.year, c.day.month, c.day.day, reminderHour),
      ),
  ];
}

class _Candidate {
  _Candidate(this.item, this.kind, this.reason, this.lead, this.day);
  final Item item;
  final ProtectionKind kind;
  final ReminderReason reason;
  final int lead;
  final DateTime day;

  /// Day first; ties in a fixed order so the same cabinet always keeps the
  /// same 48 when the cap cuts through one day.
  static int compare(_Candidate a, _Candidate b) {
    var c = a.day.compareTo(b.day);
    if (c != 0) return c;
    c = a.item.id.compareTo(b.item.id);
    if (c != 0) return c;
    c = a.kind.index.compareTo(b.kind.index);
    if (c != 0) return c;
    c = a.reason.index.compareTo(b.reason.index);
    return c != 0 ? c : a.lead.compareTo(b.lead);
  }
}

/// A short fingerprint of a plan: when it equals the last one applied,
/// nothing is sent to the platform (no cancel-and-reschedule churn on
/// every shelf move).
String planSignature(List<PlannedReminder> plan) =>
    plan.map((r) => '${r.id}@${r.fireAt.millisecondsSinceEpoch}').join(',');

/// FNV-1a, folded to a positive 31-bit int (the plugin's id type on
/// Android is a Java int). String.hashCode is not stable across runs.
int _stableId(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
