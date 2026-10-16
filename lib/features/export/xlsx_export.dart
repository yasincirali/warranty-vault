import 'dart:typed_data';

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import 'inventory_report.dart';
import 'xlsx.dart';

/// The inventory as a spreadsheet, for people who sort, filter and add up.
///
/// - "Inventory": one row per product, the cabinet's order, every end date
///   in its own column so a filter answers "what ends before June?".
/// - "Protections": one row per protection with its status and source,
///   for the questions the wide sheet can't answer in one column.
/// - "Thrown out": only when there are any.
/// Dates and amounts are real cells (sortable, summable); the amber fill
/// marks exactly what the app marks amber: ending within 30 days.
Uint8List inventoryXlsx(InventoryReport r, {required AppLocalizations l}) {
  final locale = l.localeName;
  String date(DateTime d) => fmtDateIn(locale, d);
  // Only the kinds some product has: a German cabinet has no use for the
  // UK's 30-day column.
  final kinds = [
    for (final k in ProtectionKind.values)
      if (r.active.any((v) => InventoryReport.of(v, k) != null)) k,
  ];

  // Column headers; numbers and dates are right-aligned, so their headers are.
  XText h(String t) => XText(t, XStyle.header);
  XText n(String t) => XText(t, XStyle.headerEnd);

  // Title rows: what this is and the day it is true for.
  void head(XSheet s, String title, String subtitle) {
    s
      ..add([XText(title, XStyle.title)], height: 30)
      ..add([XText(subtitle, XStyle.subtitle)], height: 20);
  }

  final subtitle = '${l.exportAsOf(date(r.today))}  ·  ${r.active.length} ${l.exportItems.toLowerCase()}';

  // --- Inventory ---------------------------------------------------------
  final inv = XSheet(
    sheetName(l.exportTitle),
    // Shelf, product frozen; widths in characters, sized for the sample
    // cabinet's longest values in both languages.
    widths: [14, 30, 18, 18, 12, 12, 13, 12, 9, 16, 22, 13, 10, for (final _ in kinds) 18, 16],
    headerRow: 3,
    frozenColumns: 2,
  );
  head(inv, l.exportTitle, subtitle);
  inv.add([
    h(l.colShelf),
    h(l.colProduct),
    h(l.colCategory),
    h(l.colStore),
    h(l.colChannel),
    h(l.colCountry),
    n(l.colPurchased),
    n(l.colPrice),
    h(l.colCurrency),
    h(l.colSerial),
    h(l.colNext),
    n(l.colNextEnd),
    n(l.colDaysLeft),
    for (final k in kinds) n(l.colEnds(kindLabel(l, k))),
    n(l.colProofEnd),
  ], height: 34);

  XCell? endCell(Protection? p) {
    if (p == null) return null;
    if (p.status == ProtectionStatus.unverified) return XText(l.notVerified, XStyle.muted);
    if (p.end == null) return XText(p.kind == ProtectionKind.manufacturer ? l.lifetime : l.noFixedEnd);
    if (p.status == ProtectionStatus.ended) return XDate(p.end!, XStyle.mutedDate);
    final d = p.daysLeft(r.today)!;
    return XDate(p.end!, d <= InventoryReport.soonDays ? XStyle.dueDate : XStyle.date);
  }

  for (final g in r.shelves) {
    for (final v in g.items) {
      final i = v.item;
      final next = r.nextEnding(v);
      final days = next?.daysLeft(r.today);
      final soon = days != null && days <= InventoryReport.soonDays;
      final legal = InventoryReport.of(v, ProtectionKind.legal);
      final proof = legal?.presumptionEnd;
      inv.add([
        XText(
          g.shelf.label.trim().isEmpty ? l.exportUnlabelled : g.shelf.label,
          g.shelf.label.trim().isEmpty ? XStyle.muted : XStyle.plain,
        ),
        XText(i.name),
        XText(categoryLabel(l, i.category)),
        XText(i.store),
        XText(channelLabel(l, i.purchase.channel)),
        XText(regionName(l, i.purchase.region)),
        XDate(i.purchase.date),
        i.price == null ? null : XNumber(i.price!.amount, XStyle.money),
        i.price == null ? null : XText(i.price!.currency),
        XText(i.serial ?? ''),
        next == null ? null : XText(kindLabel(l, next.kind), soon ? XStyle.dueText : XStyle.plain),
        next == null ? null : XDate(next.end!, soon ? XStyle.dueDate : XStyle.date),
        days == null ? null : XNumber(days, soon ? XStyle.dueCount : XStyle.count),
        for (final k in kinds) endCell(InventoryReport.of(v, k)),
        proof == null || legal!.status == ProtectionStatus.unverified
            ? null
            : XDate(proof, proof.isBefore(r.today) ? XStyle.mutedDate : XStyle.date),
      ]);
    }
  }

  // --- Protections -------------------------------------------------------
  final prot = XSheet(
    sheetName(l.sheetProtections),
    widths: [30, 24, 13, 13, 16, 10, 16, 60],
    headerRow: 3,
    frozenColumns: 1,
  );
  head(prot, l.sheetProtections, subtitle);
  prot.add([
    h(l.colProduct),
    h(l.colProtection),
    n(l.colStart),
    n(l.colEnd),
    h(l.colStatus),
    n(l.colDaysLeft),
    n(l.colProofEnd),
    h(l.colSources),
  ], height: 34);
  for (final v in r.active) {
    for (final p in v.protections) {
      final days = p.status == ProtectionStatus.active ? p.daysLeft(r.today) : null;
      final soon = days != null && days <= InventoryReport.soonDays;
      final ended = p.status == ProtectionStatus.ended;
      prot.add([
        XText(v.item.name),
        XText(kindLabel(l, p.kind), ended ? XStyle.muted : XStyle.plain),
        XDate(p.start, ended ? XStyle.mutedDate : XStyle.date),
        p.status == ProtectionStatus.unverified ? null : endCell(p),
        switch (p.status) {
          ProtectionStatus.active => XText(l.exportStatusActive, soon ? XStyle.dueText : XStyle.plain),
          ProtectionStatus.ended => XText(l.exportStatusEnded, XStyle.muted),
          ProtectionStatus.unverified => XText(l.notVerified, XStyle.muted),
        },
        days == null ? null : XNumber(days, soon ? XStyle.dueCount : XStyle.count),
        p.presumptionEnd == null || p.status == ProtectionStatus.unverified
            ? null
            : XDate(p.presumptionEnd!, ended ? XStyle.mutedDate : XStyle.date),
        XText(p.sources.join('; '), XStyle.muted),
      ]);
    }
  }

  final sheets = [inv, prot];

  // --- Thrown out --------------------------------------------------------
  if (r.disposed.isNotEmpty) {
    final out = XSheet(sheetName(l.sheetDisposed), widths: [30, 18, 18, 13, 12, 9, 14], headerRow: 3, frozenColumns: 1);
    head(out, l.sheetDisposed, '${l.exportAsOf(date(r.today))}  ·  ${r.disposed.length}');
    out.add([
      h(l.colProduct),
      h(l.colCategory),
      h(l.colStore),
      n(l.colPurchased),
      n(l.colPrice),
      h(l.colCurrency),
      n(l.colDisposed),
    ], height: 34);
    for (final v in r.disposed) {
      final i = v.item;
      out.add([
        XText(i.name),
        XText(categoryLabel(l, i.category)),
        XText(i.store),
        XDate(i.purchase.date),
        i.price == null ? null : XNumber(i.price!.amount, XStyle.money),
        i.price == null ? null : XText(i.price!.currency),
        XDate(i.disposedAt!),
      ]);
    }
    sheets.add(out);
  }

  return buildXlsx(sheets, title: '${l.exportTitle} · ${date(r.today)}', created: r.today);
}
