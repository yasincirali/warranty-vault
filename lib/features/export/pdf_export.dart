import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:flutter/widgets.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/time_rule.dart' show TimeBand;
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import 'inventory_report.dart';

/// Fonts and the logo for the PDF. The pdf package draws its own text, so
/// it needs TrueType files; the app's system font is not available to it.
class PdfAssets {
  const PdfAssets({required this.regular, required this.semiBold, required this.display, required this.mark});
  final ByteData regular;
  final ByteData semiBold;
  final ByteData display;

  /// store_listing/ikon/isaret.svg: the icon's source, not a copy.
  final String mark;

  static Future<PdfAssets> load(AssetBundle bundle) async => PdfAssets(
    regular: await bundle.load('assets/fonts/Inter-Regular.ttf'),
    semiBold: await bundle.load('assets/fonts/Inter-SemiBold.ttf'),
    display: await bundle.load('assets/fonts/InterDisplay-Bold.ttf'),
    mark: await bundle.loadString('store_listing/ikon/isaret.svg'),
  );
}

PdfColor _pdf(Color c) => PdfColor.fromInt(c.toARGB32());

/// The light theme's tokens: paper is printed, and a dark page would empty
/// the printer. Same colour rules as the app: amber only for a protection
/// ending within 30 days, muted for what has ended, nothing decorative.
final _ink = _pdf(VColors.light.text);
final _secondary = _pdf(VColors.light.textSecondary);
final _muted = _pdf(VColors.light.muted);
final _line = _pdf(VColors.light.border);
final _divider = _pdf(VColors.light.divider);
final _paper = _pdf(VColors.light.background);
final _tile = _pdf(VColors.light.tile);
final _track = _pdf(VColors.light.track);
final _due = _pdf(VColors.light.deadline);
final _dueSurface = _pdf(VColors.light.deadlineSurface);
final _brand = _pdf(VBrand.splash);
final _white = _pdf(VColors.light.surface);

/// The app paints the passed part as text at 22 % over the track; a PDF
/// fill has no alpha without a graphics state, so the blend is done here.
PdfColor _over(PdfColor top, PdfColor under, double a) => PdfColor(
  under.red + (top.red - under.red) * a,
  under.green + (top.green - under.green) * a,
  under.blue + (top.blue - under.blue) * a,
);
final _passed = _over(_ink, _track, .22);
final _ended = _over(_ink, _track, .1);

/// Builds the inventory as an A4 PDF.
///
/// Layout (decided 16 Oct, "tasarım çok kritik"):
/// 1. Cover strip: logo tile, "Inventory", the date it is valid for.
/// 2. Three numbers: products, total paid (per currency), ending soon.
/// 3. "Needs attention": only when something ends within 30 days; the first
///    thing to read, like the home screen.
/// 4. The cabinet shelf by shelf, under the shelf's own Dymo label: photo,
///    name, where and when bought, price, then one time rule per protection
///    (the app's single graphic, drawn the same way).
/// 5. Thrown-out items, small, last.
/// Every page: the disclaimer and "page x of y".
///
/// [photo] returns PNG/JPEG bytes for an item's photo path, already small
/// (the PDF would otherwise carry full-size camera photos), or null.
Future<Uint8List> inventoryPdf(
  InventoryReport r, {
  required AppLocalizations l,
  required PdfAssets assets,
  required Future<Uint8List?> Function(String photoPath) photo,
}) async {
  final regular = pw.Font.ttf(assets.regular);
  final semi = pw.Font.ttf(assets.semiBold);
  final display = pw.Font.ttf(assets.display);
  final s = _Styles(regular, semi, display);

  final photos = <String, pw.ImageProvider>{};
  for (final v in [...r.active, ...r.disposed]) {
    final path = v.item.photoPath;
    if (path == null || photos.containsKey(path)) continue;
    final bytes = await photo(path);
    if (bytes != null) photos[path] = pw.MemoryImage(bytes);
  }

  final locale = l.localeName;
  String date(DateTime d) => fmtDateIn(locale, d);
  final asOf = l.exportAsOf(date(r.today));

  final doc = pw.Document(
    title: '${l.exportTitle} · ${date(r.today)}',
    creator: l.appTitle,
    theme: pw.ThemeData.withFont(base: regular, bold: semi),
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
        theme: pw.ThemeData.withFont(base: regular, bold: semi),
      ),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Row(
                children: [
                  _markTile(assets.mark, 16),
                  pw.SizedBox(width: 8),
                  pw.Text('${l.exportTitle} · ${date(r.today)}', style: s.caption),
                ],
              ),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _divider, width: .6)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(child: pw.Text(l.disclaimer, style: s.caption)),
            pw.Text(l.exportPage(ctx.pageNumber, ctx.pagesCount), style: s.caption),
          ],
        ),
      ),
      build: (ctx) => [
        _cover(r, l, s, assets.mark, asOf, locale),
        pw.SizedBox(height: 18),
        _numbers(r, l, s, locale),
        if (r.due.isNotEmpty) ...[pw.SizedBox(height: 22), ..._attention(r, l, s, date)],
        // Before the first bars, not after the last one (Rafım Ar-Ge 30 Oct):
        // on page 2 nobody reading page 1 found it.
        if (r.active.isNotEmpty) ...[pw.SizedBox(height: 10), pw.Text(l.exportLegend, style: s.caption)],
        for (final g in r.shelves) ...[
          pw.SizedBox(height: 22),
          // The label travels with its first item so a shelf name never sits
          // alone at the bottom of a page (MultiPage would split a Column).
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _shelfLabel(g, l, s),
                pw.SizedBox(height: 10),
                _itemCard(g.items.first, r, l, s, photos, date),
              ],
            ),
          ),
          for (final v in g.items.skip(1)) ...[pw.SizedBox(height: 8), _itemCard(v, r, l, s, photos, date)],
        ],
        if (r.disposed.isNotEmpty) ...[pw.SizedBox(height: 22), _disposed(r, l, s, locale, date)],
      ],
    ),
  );

  return doc.save();
}

class _Styles {
  _Styles(pw.Font regular, pw.Font semi, pw.Font display)
    : title = pw.TextStyle(font: display, fontSize: 30, color: _ink, letterSpacing: -.6),
      big = pw.TextStyle(font: display, fontSize: 22, color: _ink, letterSpacing: -.4),
      bigSmall = pw.TextStyle(font: display, fontSize: 14, color: _ink),
      section = pw.TextStyle(font: semi, fontSize: 10.5, color: _secondary, letterSpacing: .2),
      name = pw.TextStyle(font: semi, fontSize: 12, color: _ink),
      price = pw.TextStyle(font: semi, fontSize: 12, color: _ink),
      body = pw.TextStyle(font: regular, fontSize: 9.5, color: _ink),
      meta = pw.TextStyle(font: regular, fontSize: 9, color: _secondary, lineSpacing: 1.5),
      label = pw.TextStyle(font: regular, fontSize: 8.5, color: _secondary),
      strong = pw.TextStyle(font: semi, fontSize: 8.5, color: _ink),
      caption = pw.TextStyle(font: regular, fontSize: 7.5, color: _muted),
      tape = pw.TextStyle(font: semi, fontSize: 8.5, color: _white, letterSpacing: .8);

  final pw.TextStyle title, big, bigSmall, section, name, price, body, meta, label, strong, caption, tape;
}

pw.Widget _markTile(String svg, double size) => pw.Container(
  width: size,
  height: size,
  decoration: pw.BoxDecoration(color: _brand, borderRadius: pw.BorderRadius.circular(size * .225)),
  child: pw.SvgImage(svg: svg),
);

pw.Widget _cover(InventoryReport r, AppLocalizations l, _Styles s, String mark, String asOf, String locale) {
  final regions = {for (final v in r.active) v.item.purchase.region};
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      _markTile(mark, 48),
      pw.SizedBox(width: 14),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(l.exportTitle, style: s.title),
            pw.SizedBox(height: 2),
            pw.Text([asOf, if (regions.length == 1) regionName(l, regions.first)].join('  ·  '), style: s.meta),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _numbers(InventoryReport r, AppLocalizations l, _Styles s, String locale) {
  pw.Widget cell({required pw.Widget value, required String label}) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(color: _paper, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          value,
          pw.SizedBox(height: 4),
          pw.Text(label, style: s.label.copyWith(color: _secondary)),
        ],
      ),
    ),
  );

  final totals = r.totals;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      cell(
        value: pw.Text('${r.active.length}', style: s.big),
        label: l.exportItems,
      ),
      pw.SizedBox(width: 8),
      cell(
        value: totals.isEmpty
            ? pw.Text('–', style: s.big)
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // One line per currency; the first is the largest and gets the
                  // big size, the rest stay readable but quieter.
                  pw.Text(fmtMoneyIn(locale, totals.first), style: s.big),
                  for (final m in totals.skip(1)) pw.Text(fmtMoneyIn(locale, m), style: s.bigSmall),
                ],
              ),
        label: l.exportTotal,
      ),
      // No third "ending within 30 days" tile (Rafım Ar-Ge 30 Oct): the
      // "Needs attention" list right below names the same products with
      // their dates; the count spent the page's one colour on a repeat.
    ],
  );
}

/// One row per protection, each its own widget: a cabinet full of things
/// bought the same month can list more than a page, and one widget taller
/// than a page cannot be laid out.
List<pw.Widget> _attention(InventoryReport r, AppLocalizations l, _Styles s, String Function(DateTime) date) {
  pw.Widget row(Due d) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: pw.BoxDecoration(color: _dueSurface, borderRadius: pw.BorderRadius.circular(8)),
    child: pw.Row(
      children: [
        pw.Expanded(flex: 5, child: pw.Text(d.view.item.name, style: s.name.copyWith(fontSize: 10.5))),
        pw.Expanded(flex: 4, child: pw.Text(kindLabel(l, d.protection.kind), style: s.body)),
        pw.SizedBox(
          width: 92,
          child: pw.Text(l.exportDaysLeft(d.days), style: s.strong.copyWith(color: _due, fontSize: 9.5)),
        ),
        pw.SizedBox(
          width: 70,
          child: pw.Text(date(d.protection.end!), style: s.body, textAlign: pw.TextAlign.right),
        ),
      ],
    ),
  );

  return [
    // Heading kept with the first row, like a shelf label.
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l.exportAttention, style: s.section.copyWith(color: _due)),
          pw.SizedBox(height: 3),
          pw.Text(l.exportAttentionWhy, style: s.meta),
          pw.SizedBox(height: 4),
          row(r.due.first),
        ],
      ),
    ),
    for (final d in r.due.skip(1)) row(d),
  ];
}

/// The shelf's own label-maker tape, as on the cabinet.
pw.Widget _shelfLabel(ShelfGroup g, AppLocalizations l, _Styles s) {
  final named = g.shelf.label.trim().isNotEmpty;
  return pw.Row(
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(6, 3, 6, 3),
        decoration: pw.BoxDecoration(
          color: named ? _ink : null,
          border: named ? null : pw.Border.all(color: _line, width: .8),
          borderRadius: pw.BorderRadius.circular(2.5),
        ),
        child: pw.Text(
          named ? g.shelf.label : l.exportUnlabelled,
          style: named ? s.tape : s.tape.copyWith(color: _muted),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text('${g.items.length}', style: s.label),
    ],
  );
}

pw.Widget _photo(Item item, Map<String, pw.ImageProvider> photos, _Styles s, double size) {
  final img = item.photoPath == null ? null : photos[item.photoPath];
  if (img == null) {
    // No photo: the name's first letter on the neutral tile, like a
    // placeholder, never a colour that would suggest a status.
    final initial = item.name.trim().isEmpty ? '?' : item.name.trim().characters1.toUpperCase();
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(initial, style: s.big.copyWith(color: _secondary)),
    );
  }
  // A cut-out stands on the paper tile like on a shelf; a full photo fills
  // its rounded square.
  return item.photoCutout
      ? pw.Container(
          width: size,
          height: size,
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(color: _paper, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Image(img, fit: pw.BoxFit.contain),
        )
      : pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: pw.SizedBox(
            width: size,
            height: size,
            child: pw.Image(img, fit: pw.BoxFit.cover),
          ),
        );
}

extension on String {
  /// First user-perceived letter for the common cases (Latin, Turkish);
  /// a full grapheme splitter is not worth a dependency here.
  String get characters1 => runes.isEmpty ? '' : String.fromCharCode(runes.first);
}

pw.Widget _itemCard(
  ItemView v,
  InventoryReport r,
  AppLocalizations l,
  _Styles s,
  Map<String, pw.ImageProvider> photos,
  String Function(DateTime) date,
) {
  final i = v.item;
  final where = [
    if (i.store.trim().isNotEmpty) i.store.trim(),
    channelLabel(l, i.purchase.channel),
    regionName(l, i.purchase.region),
  ].join('  ·  ');
  final when = [
    '${l.colPurchased}: ${date(i.purchase.date)}',
    if (i.serial != null && i.serial!.trim().isNotEmpty) '${l.colSerial}: ${i.serial!.trim()}',
  ].join('  ·  ');

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _white,
      border: pw.Border.all(color: _line, width: .8),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _photo(i, photos, s, 56),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(i.name, style: s.name),
                  pw.SizedBox(height: 3),
                  pw.Text(where, style: s.meta),
                  pw.Text(when, style: s.meta),
                ],
              ),
            ),
            if (i.price != null) ...[
              pw.SizedBox(width: 12),
              pw.Text(fmtMoneyIn(l.localeName, i.price!), style: s.price),
            ],
          ],
        ),
        pw.SizedBox(height: 10),
        if (v.protections.isEmpty)
          pw.Text(l.exportNoProtection, style: s.label)
        else
          for (final p in v.protections) _protectionRow(p, r.today, l, s, date, TimeBand.axisOf(v.protections)),
      ],
    ),
  );
}

pw.Widget _protectionRow(
  Protection p,
  DateTime today,
  AppLocalizations l,
  _Styles s,
  String Function(DateTime) date,
  (DateTime, DateTime)? axis,
) {
  final days = p.daysLeft(today);
  final active = p.status == ProtectionStatus.active;
  final urgent = active && days != null && days >= 0 && days <= InventoryReport.soonDays;
  final ended = p.status == ProtectionStatus.ended;

  final pw.Widget status;
  if (p.status == ProtectionStatus.unverified) {
    status = pw.Text(l.notVerified, style: s.label.copyWith(color: _muted));
  } else if (ended) {
    status = pw.Text(l.endedOn(date(p.end!)), style: s.label.copyWith(color: _muted));
  } else if (p.end == null) {
    status = pw.Text(l.noFixedEnd, style: s.label);
  } else if (urgent) {
    status = pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: l.exportDaysLeft(days),
            style: s.strong.copyWith(color: _due),
          ),
          pw.TextSpan(
            text: '  ·  ${date(p.end!)}',
            style: s.label.copyWith(color: _due),
          ),
        ],
      ),
    );
  } else {
    status = pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '${remainingLabel(l, today, p.end!)} ${l.left}', style: s.strong),
          pw.TextSpan(text: '  ·  ${date(p.end!)}', style: s.label),
        ],
      ),
    );
  }

  final proof = active && p.presumptionEnd != null && p.sellerBearsProofOn(today)
      ? l.exportProofUntil(date(p.presumptionEnd!))
      : null;

  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 5),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 118,
              child: pw.Text(kindLabel(l, p.kind), style: s.body.copyWith(color: ended ? _muted : _ink)),
            ),
            pw.Expanded(child: _rule(p, today, urgent, axis)),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 150,
              child: pw.Align(alignment: pw.Alignment.centerRight, child: status),
            ),
          ],
        ),
        if (proof != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 118, top: 1),
            child: pw.Text(proof, style: s.caption.copyWith(color: _secondary)),
          ),
      ],
    ),
  );
}

/// [TimeRule] on paper. One axis per product, as on its page in the app
/// (#29; Rafım Ar-Ge 30 Oct): a 14-day return window is a short piece next
/// to a two-year right, not a bar of the same length. On that axis, the protection's own
/// piece of track, the part that has passed, a ring at today (amber when
/// urgent) and a tick where the burden of proof moves. Without an axis
/// (open-ended or unverified) only the empty track is drawn.
pw.Widget _rule(Protection p, DateTime today, bool urgent, (DateTime, DateTime)? axis) {
  final ended = p.status == ProtectionStatus.ended;
  final unverified = p.status == ProtectionStatus.unverified;

  return pw.SizedBox(
    height: 10,
    child: pw.CustomPaint(
      painter: (canvas, size) {
        const h = 4.0;
        // A short window stays a visible piece (the app's minSpan, scaled
        // to paper).
        const minPiece = 10.0;
        final y = (size.y - h) / 2;
        if (axis == null || p.end == null || unverified) {
          canvas
            ..setFillColor(_track)
            ..drawRRect(0, y, size.x, h, h / 2, h / 2)
            ..fillPath();
          return;
        }
        final total = axis.$2.difference(axis.$1).inDays.toDouble();
        double x(DateTime d) => size.x * (d.difference(axis.$1).inDays / total).clamp(0.0, 1.0);
        final from = x(p.start);
        final to = math.min(size.x, math.max(x(p.end!), from + minPiece));
        final now = x(today).clamp(from, to);
        canvas
          ..setFillColor(ended ? _ended : _track)
          ..drawRRect(from, y, to - from, h, h / 2, h / 2)
          ..fillPath();
        if (!ended && now > from) {
          canvas
            ..setFillColor(_passed)
            ..drawRRect(from, y, now - from, h, h / 2, h / 2)
            ..fillPath();
        }
        final proof = p.presumptionEnd == null ? null : x(p.presumptionEnd!);
        if (proof != null && proof > from && proof < to && !ended) {
          canvas
            ..setFillColor(_ink)
            ..drawRect(proof - .5, 0, 1, size.y)
            ..fillPath();
        }
        if (!ended) {
          final cx = now.clamp(4.0, size.x - 4.0);
          canvas
            ..setFillColor(_white)
            ..drawEllipse(cx, size.y / 2, 4, 4)
            ..fillPath()
            ..setStrokeColor(urgent ? _due : _ink)
            ..setLineWidth(1.6)
            ..drawEllipse(cx, size.y / 2, 3.6, 3.6)
            ..strokePath();
        }
      },
    ),
  );
}

pw.Widget _disposed(InventoryReport r, AppLocalizations l, _Styles s, String locale, String Function(DateTime) date) {
  pw.Widget cell(String t, {pw.TextStyle? style, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Text(t, style: style ?? s.body, textAlign: align),
  );
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(l.sheetDisposed, style: s.section),
      pw.SizedBox(height: 6),
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(4),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(2),
        },
        border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _divider, width: .6)),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line, width: .8)),
            ),
            children: [
              cell(l.colProduct, style: s.label),
              cell(l.colStore, style: s.label),
              cell(l.colPurchased, style: s.label),
              cell(l.colDisposed, style: s.label),
              cell(l.colPrice, style: s.label, align: pw.TextAlign.right),
            ],
          ),
          for (final v in r.disposed)
            pw.TableRow(
              children: [
                cell(v.item.name, style: s.body.copyWith(color: _secondary)),
                cell(v.item.store, style: s.body.copyWith(color: _secondary)),
                cell(date(v.item.purchase.date), style: s.body.copyWith(color: _secondary)),
                cell(date(v.item.disposedAt!), style: s.body.copyWith(color: _secondary)),
                cell(
                  v.item.price == null ? '' : fmtMoneyIn(locale, v.item.price!),
                  style: s.body.copyWith(color: _secondary),
                  align: pw.TextAlign.right,
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
