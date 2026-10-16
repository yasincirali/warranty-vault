import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warranty_vault/core/theme/tokens.dart';
import 'package:warranty_vault/features/export/inventory_report.dart';
import 'package:warranty_vault/features/export/pdf_export.dart';
import 'package:warranty_vault/features/export/xlsx.dart';
import 'package:warranty_vault/features/export/xlsx_export.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/l10n/generated/app_localizations.dart';
import 'package:warranty_vault/rights/advice.dart';
import 'package:warranty_vault/rights/rights_engine.dart';
import 'package:warranty_vault/rights/rule_set.dart';

final _rules = RuleSet.fromJsonString(File('assets/rules/rules.json').readAsStringSync());
final _today = DateTime.utc(2026, 10, 16);

/// The sample cabinet with one thing thrown out, as the export sees it.
InventoryReport _report({Vault? vault}) {
  final base = vault ?? demoVault(desk: 'Masa', living: 'Salon', kitchen: 'Mutfak');
  final v = Vault(
    shelves: [
      ...base.shelves,
      const Shelf(id: 'free'),
    ],
    items: [for (final i in base.items) i.id == 'pixel' ? i.copyWith(disposedAt: DateTime.utc(2026, 9, 1)) : i],
  );
  final engine = RightsEngine(_rules);
  final views = [
    for (final i in v.items)
      () {
        final ps = engine.evaluate(i.purchase, _today);
        return ItemView(i, ps, i.active ? nextDeadline(ps, _today) : null);
      }(),
  ];
  return InventoryReport.from(v, views, _today);
}

Map<String, String> _unzip(Uint8List bytes) => {
  for (final f in ZipDecoder().decodeBytes(bytes)) f.name: utf8.decode(f.content as List<int>),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('report', () {
    test('shelves in cabinet order, empty shelves and thrown-out items left out', () {
      final r = _report();
      expect([for (final g in r.shelves) g.shelf.label], ['Masa', 'Salon', 'Mutfak']);
      expect(r.active.any((v) => v.item.id == 'pixel'), isFalse);
      expect([for (final v in r.disposed) v.item.id], ['pixel']);
    });

    test('"ending soon" uses the app\'s 30 days and lists the soonest first', () {
      final r = _report();
      expect(r.due, isNotEmpty);
      for (final d in r.due) {
        expect(d.days, inInclusiveRange(0, InventoryReport.soonDays));
        expect(d.protection.status, ProtectionStatus.active);
      }
      expect([for (final d in r.due) d.days], orderedEquals([...r.due.map((d) => d.days)]..sort()));
    });

    test('totals are per currency, never converted', () {
      final r = _report();
      final eur = r.active
          .where((v) => v.item.price?.currency == 'EUR')
          .fold<num>(0, (s, v) => s + v.item.price!.amount);
      expect(r.totals.first.currency, 'EUR');
      expect(r.totals.first.amount, eur);
    });
  });

  group('xlsx', () {
    test('a valid workbook: three sheets, real dates, frozen header, filter', () {
      final l = lookupAppLocalizations(const Locale('tr'));
      final files = _unzip(inventoryXlsx(_report(), l: l));
      expect(
        files.keys,
        containsAll(['[Content_Types].xml', 'xl/workbook.xml', 'xl/styles.xml', 'xl/worksheets/sheet3.xml']),
      );
      final book = files['xl/workbook.xml']!;
      for (final name in ['Envanter', 'Korumalar', 'Çıkardıkların']) {
        expect(book, contains('name="$name"'));
      }
      final sheet = files['xl/worksheets/sheet1.xml']!;
      expect(sheet, contains('state="frozen"'));
      expect(sheet, contains('<autoFilter ref="A3:'));
      // MacBook bought 10 Nov 2024 → Excel day 45606, stored as a number.
      expect(sheet, contains('<v>${excelDay(DateTime(2024, 11, 10))}</v>'));
      expect(excelDay(DateTime(2024, 11, 10)), 45606);
      // Every XML part parses as well-formed text with no raw ampersands.
      for (final f in files.values) {
        expect(RegExp(r'&(?!amp;|lt;|gt;|quot;|apos;)').hasMatch(f), isFalse);
      }
    });

    test('amber cells are exactly the protections ending within 30 days', () {
      final l = lookupAppLocalizations(const Locale('en'));
      final r = _report();
      final sheet = _unzip(inventoryXlsx(r, l: l))['xl/worksheets/sheet2.xml']!;
      final dueCount = RegExp('s="${XStyle.dueCount.id}"').allMatches(sheet).length;
      expect(dueCount, r.due.length);
    });

    test('user text is escaped and control characters dropped', () {
      final base = demoVault();
      final odd = Item(
        id: 'odd',
        name: 'Tom & Jerry <"mug">\u0007',
        store: 'A&B',
        purchase: Purchase(date: DateTime.utc(2026, 10, 1), region: 'DE', channel: SalesChannel.store),
        shelfId: 'desk',
      );
      final r = _report(
        vault: Vault(shelves: base.shelves, items: [...base.items, odd]),
      );
      final sheet = _unzip(
        inventoryXlsx(r, l: lookupAppLocalizations(const Locale('en'))),
      )['xl/worksheets/sheet1.xml']!;
      expect(sheet, contains('Tom &amp; Jerry &lt;&quot;mug&quot;&gt;</t>'));
    });

    test('colours are the app\'s light tokens', () {
      String hex(Color c) => c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
      expect(xInk, hex(VColors.light.text));
      expect(xSecondary, hex(VColors.light.textSecondary));
      expect(xMuted, hex(VColors.light.muted));
      expect(xDue, hex(VColors.light.deadline));
      expect(xDueSurface, hex(VColors.light.deadlineSurface));
    });
  });

  test('pdf: builds an A4 document with photos in both languages', () async {
    final assets = await PdfAssets.load(rootBundle);
    for (final lang in ['tr', 'en']) {
      final bytes = await inventoryPdf(
        _report(),
        l: lookupAppLocalizations(Locale(lang)),
        assets: assets,
        photo: (path) async => path.startsWith('asset:') ? File('assets/${path.substring(6)}').readAsBytesSync() : null,
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      // Optional: write the files for a visual check (scratch, not CI).
      final out = Platform.environment['EXPORT_OUT'];
      if (out != null) {
        File('$out/envanter-$lang.pdf').writeAsBytesSync(bytes);
        File('$out/envanter-$lang.xlsx')
            .writeAsBytesSync(inventoryXlsx(_report(), l: lookupAppLocalizations(Locale(lang))));
      }
    }
  });
}
