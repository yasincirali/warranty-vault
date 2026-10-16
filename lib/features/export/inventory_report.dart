import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/domain/vault.dart';

/// One shelf of the export, in cabinet order. Empty shelves are left out:
/// a printed page has no use for the free shelf at the bottom.
class ShelfGroup {
  const ShelfGroup(this.shelf, this.items);
  final Shelf shelf;
  final List<ItemView> items;
}

/// A protection that ends within [InventoryReport.soonDays], with its item.
class Due {
  const Due(this.view, this.protection, this.days);
  final ItemView view;
  final Protection protection;
  final int days;
}

/// Everything the PDF and the spreadsheet show, computed once, so both
/// files say the same thing and neither builder runs rights logic.
/// "Today" is the moment of export, not the purchase date: a file made on
/// 16 Oct says what was still covered on 16 Oct.
class InventoryReport {
  InventoryReport._(this.today, this.shelves, this.disposed, this.due, this.totals);

  /// The app's own threshold for "act now" (home "Needs attention", the
  /// amber colour); the files use the same one so they match the screen.
  static const soonDays = 30;

  final DateTime today;
  final List<ShelfGroup> shelves;
  final List<ItemView> disposed;

  /// Soonest first.
  final List<Due> due;

  /// Amount paid per currency, the currency most items were bought in
  /// first. Never converted: a rate would be a number we made up for a day
  /// nobody asked about. (Not "largest first": 20.000 TRY is not more than
  /// 1.000 EUR.)
  final List<Money> totals;

  List<ItemView> get active => [for (final g in shelves) ...g.items];
  bool get isEmpty => active.isEmpty && disposed.isEmpty;

  /// Items with at least one protection ending soon (one item can have two).
  int get dueItems => {for (final d in due) d.view.item.id}.length;

  factory InventoryReport.from(Vault vault, List<ItemView> views, DateTime today) {
    final byId = {for (final v in views) v.item.id: v};
    final shelves = <ShelfGroup>[];
    for (final s in vault.shelves) {
      final items = [for (final i in vault.on(s.id)) ?byId[i.id]];
      if (items.isNotEmpty) shelves.add(ShelfGroup(s, items));
    }
    final disposed = [for (final i in vault.disposed) ?byId[i.id]]
      ..sort((a, b) => b.item.disposedAt!.compareTo(a.item.disposedAt!));

    final due = <Due>[
      for (final g in shelves)
        for (final v in g.items)
          for (final p in v.protections)
            if (p.status == ProtectionStatus.active && p.end != null)
              if (p.daysLeft(today)! case final d when d >= 0 && d <= soonDays) Due(v, p, d),
    ]..sort((a, b) => a.days.compareTo(b.days));

    final sums = <String, num>{};
    final counts = <String, int>{};
    for (final g in shelves) {
      for (final v in g.items) {
        final p = v.item.price;
        if (p == null) continue;
        sums[p.currency] = (sums[p.currency] ?? 0) + p.amount;
        counts[p.currency] = (counts[p.currency] ?? 0) + 1;
      }
    }
    final totals = [for (final e in sums.entries) Money(e.value, e.key)]
      ..sort((a, b) => counts[b.currency]!.compareTo(counts[a.currency]!));

    return InventoryReport._(today, shelves, disposed, due, totals);
  }

  /// The active protection that ends first (any distance away), for the
  /// spreadsheet's "ends next" column; null when nothing with an end runs.
  Protection? nextEnding(ItemView v) {
    Protection? best;
    for (final p in v.protections) {
      if (p.status != ProtectionStatus.active || p.end == null) continue;
      if (best == null || p.end!.isBefore(best.end!)) best = p;
    }
    return best;
  }

  /// The one protection of [kind] on [v], if the rules gave it one.
  static Protection? of(ItemView v, ProtectionKind kind) {
    for (final p in v.protections) {
      if (p.kind == kind) return p;
    }
    return null;
  }
}
