import 'rights_engine.dart';

/// What the user says happened, in the "Bir sorun var" flow.
enum IssueType { defect, arrivedDamaged, notAsDescribed, lostOrStolen }

enum AdviceAction {
  /// Withdraw / return within the return window; no reason needed.
  returnItem,

  /// UK: reject faulty goods for a full refund within 30 days.
  rejectGoods,

  /// Statutory remedy from the seller: repair or replacement first.
  askSellerRepair,
  askManufacturer,

  /// Region rule not verified yet: point to the official consumer body.
  checkLocalRules,

  /// Loss and theft are never covered by guarantees.
  insurance,
  notCovered,
}

class Advice {
  const Advice(this.action, {this.basis, this.sellerBearsProof});

  final AdviceAction action;

  /// The protection the advice rests on, so the UI can cite its end date
  /// and source.
  final Protection? basis;
  final bool? sellerBearsProof;
}

/// Picks the single best next step. The order is the cheapest, strongest
/// remedy first: a no-questions return beats a repair claim, a seller claim
/// beats a manufacturer claim (the seller cannot send you elsewhere).
Advice adviseFor(IssueType issue, List<Protection> protections, DateTime today) {
  if (issue == IssueType.lostOrStolen) return const Advice(AdviceAction.insurance);

  Protection? active(ProtectionKind k) {
    for (final p in protections) {
      if (p.kind == k && p.status == ProtectionStatus.active) return p;
    }
    return null;
  }

  final ret = active(ProtectionKind.returnWindow);
  if (ret != null) return Advice(AdviceAction.returnItem, basis: ret);

  final reject = active(ProtectionKind.shortTermReject);
  if (reject != null) return Advice(AdviceAction.rejectGoods, basis: reject);

  final legal = active(ProtectionKind.legal);
  if (legal != null) {
    return Advice(AdviceAction.askSellerRepair,
        basis: legal, sellerBearsProof: legal.sellerBearsProofOn(today));
  }

  final maker =
      active(ProtectionKind.manufacturer) ?? active(ProtectionKind.extended);
  if (maker != null) return Advice(AdviceAction.askManufacturer, basis: maker);

  final unverifiedLegal = protections.where((p) =>
      p.kind == ProtectionKind.legal && p.status == ProtectionStatus.unverified);
  if (unverifiedLegal.isNotEmpty) {
    return Advice(AdviceAction.checkLocalRules, basis: unverifiedLegal.first);
  }
  return const Advice(AdviceAction.notCovered);
}

/// The soonest-ending active protection within [windowDays], or null.
/// Drives the "İlgilen" section: one line per item, most urgent first.
Protection? nextDeadline(List<Protection> protections, DateTime today,
    {int windowDays = 30}) {
  Protection? best;
  for (final p in protections) {
    if (p.status != ProtectionStatus.active) continue;
    final d = p.daysLeft(today);
    if (d == null || d < 0 || d > windowDays) continue;
    if (best == null || d < best.daysLeft(today)!) best = p;
  }
  return best;
}
