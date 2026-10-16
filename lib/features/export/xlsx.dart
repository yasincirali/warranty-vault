import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A small .xlsx writer: inline strings, real dates and numbers, one fixed
/// style sheet, frozen header, filter, column widths.
///
/// Hand-written rather than a spreadsheet package: the export needs a few
/// styles, not formulas or reading, and the packages that exist either
/// pull in a lot or write dates as text (which Excel cannot sort).
/// The output opens in Excel, Numbers, Google Sheets and LibreOffice.
enum XStyle {
  plain(0),
  title(1),
  subtitle(2),
  header(3),
  date(4),
  money(5),
  count(6),
  dueCount(7),
  dueDate(8),
  muted(9),
  mutedDate(10),
  dueText(11),

  /// Header over a date or number column: right-aligned like its values.
  headerEnd(12);

  const XStyle(this.id);
  final int id;
}

sealed class XCell {
  const XCell(this.style);
  final XStyle style;
}

class XText extends XCell {
  const XText(this.text, [super.style = XStyle.plain]);
  final String text;
}

class XNumber extends XCell {
  const XNumber(this.value, [super.style = XStyle.plain]);
  final num value;
}

class XDate extends XCell {
  const XDate(this.value, [super.style = XStyle.date]);
  final DateTime value;
}

class XSheet {
  XSheet(this.name, {required this.widths, this.headerRow = 0, this.frozenColumns = 0});

  /// Excel allows 31 characters and none of : \ / ? * [ ].
  final String name;
  final List<double> widths;

  /// 1-based row of the column headers; rows above it (title) and it stay
  /// visible while scrolling, and the filter starts there. 0 = none.
  final int headerRow;
  final int frozenColumns;
  final rows = <List<XCell?>>[];
  final rowHeights = <int, double>{};

  void add(List<XCell?> row, {double? height}) {
    rows.add(row);
    if (height != null) rowHeights[rows.length] = height;
  }
}

String sheetName(String s) {
  final clean = s.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
  return clean.length > 31 ? clean.substring(0, 31) : clean;
}

String _col(int i) {
  var n = i + 1;
  var s = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// Characters XML 1.0 forbids (control codes from pasted text) are dropped
/// instead of producing a file Excel refuses to open.
String _esc(String s) => s
    .replaceAll(RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Excel day number. Dates are calendar days (no time, no zone), so the
/// date the user typed is the date the cell shows anywhere in the world.
int excelDay(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1899, 12, 30)).inDays;

String _sheetXml(XSheet s) {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    )
    // Printed: all columns on one landscape page width, as many pages down
    // as it takes.
    ..write('<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>')
    ..write('<sheetViews><sheetView workbookViewId="0" zoomScale="110">');
  if (s.headerRow > 0 || s.frozenColumns > 0) {
    final top = '${_col(s.frozenColumns)}${s.headerRow + 1}';
    final pane = s.frozenColumns > 0 && s.headerRow > 0 ? 'bottomRight' : (s.headerRow > 0 ? 'bottomLeft' : 'topRight');
    b.write(
      '<pane ${s.frozenColumns > 0 ? 'xSplit="${s.frozenColumns}" ' : ''}'
      '${s.headerRow > 0 ? 'ySplit="${s.headerRow}" ' : ''}'
      'topLeftCell="$top" activePane="$pane" state="frozen"/>'
      '<selection pane="$pane" activeCell="$top" sqref="$top"/>',
    );
  }
  b
    ..write('</sheetView></sheetViews>')
    ..write('<sheetFormatPr defaultRowHeight="20" customHeight="1"/><cols>');
  for (final (i, w) in s.widths.indexed) {
    b.write('<col min="${i + 1}" max="${i + 1}" width="$w" customWidth="1"/>');
  }
  b.write('</cols><sheetData>');
  for (final (r, row) in s.rows.indexed) {
    final n = r + 1;
    final h = s.rowHeights[n];
    b.write('<row r="$n"${h == null ? '' : ' ht="$h" customHeight="1"'}>');
    for (final (c, cell) in row.indexed) {
      if (cell == null) continue;
      final ref = '${_col(c)}$n';
      switch (cell) {
        case XText(:final text):
          if (text.isEmpty) {
            b.write('<c r="$ref" s="${cell.style.id}"/>');
          } else {
            b.write(
              '<c r="$ref" s="${cell.style.id}" t="inlineStr"><is><t xml:space="preserve">${_esc(text)}</t></is></c>',
            );
          }
        case XNumber(:final value):
          b.write('<c r="$ref" s="${cell.style.id}"><v>$value</v></c>');
        case XDate(:final value):
          b.write('<c r="$ref" s="${cell.style.id}"><v>${excelDay(value)}</v></c>');
      }
    }
    b.write('</row>');
  }
  b.write('</sheetData>');
  if (s.headerRow > 0 && s.rows.length > s.headerRow) {
    b.write('<autoFilter ref="${_filterRef(s)}"/>');
  }
  b.write(
    '<pageMargins left="0.5" right="0.5" top="0.6" bottom="0.6" header="0.3" footer="0.3"/>'
    '<pageSetup paperSize="9" orientation="landscape" fitToWidth="1" fitToHeight="0"/>'
    '</worksheet>',
  );
  return b.toString();
}

String _filterRef(XSheet s) => 'A${s.headerRow}:${_col(s.widths.length - 1)}${s.rows.length}';

// Colours are the app's light tokens (VColors.light) as ARGB hex: ink,
// secondary, muted, deadline, deadline surface. Duplicated as literals
// because this file is pure Dart; xlsx_test checks they still match.
const xInk = 'FF16181D';
const xSecondary = 'FF575B64';
const xMuted = 'FF6E727A';
const xDue = 'FFA04E00';
const xDueSurface = 'FFFFF1D6';

const _styles =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="6">'
    '<font><sz val="11"/><color rgb="$xInk"/><name val="Calibri"/><family val="2"/></font>'
    '<font><b/><sz val="18"/><color rgb="$xInk"/><name val="Calibri"/><family val="2"/></font>'
    '<font><sz val="10"/><color rgb="$xSecondary"/><name val="Calibri"/><family val="2"/></font>'
    '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
    '<font><b/><sz val="11"/><color rgb="$xDue"/><name val="Calibri"/><family val="2"/></font>'
    '<font><sz val="11"/><color rgb="$xMuted"/><name val="Calibri"/><family val="2"/></font>'
    '</fonts>'
    '<fills count="4">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="$xInk"/><bgColor indexed="64"/></patternFill></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="$xDueSurface"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="13">'
    // 0 plain
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" indent="1"/></xf>'
    // 1 title
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 2 subtitle
    '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="top"/></xf>'
    // 3 header: ink band, white bold, wraps so long labels stay readable
    '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" wrapText="1" indent="1"/></xf>'
    // 4 date: built-in 14 follows the reader's own date format
    '<xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 5 money: built-in 4 (#,##0.00) follows the reader's separators
    '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 6 count
    '<xf numFmtId="1" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 7 due count
    '<xf numFmtId="1" fontId="4" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 8 due date
    '<xf numFmtId="14" fontId="4" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 9 muted
    '<xf numFmtId="0" fontId="5" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center" indent="1"/></xf>'
    // 10 muted date
    '<xf numFmtId="14" fontId="5" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>'
    // 11 due text
    '<xf numFmtId="0" fontId="4" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" indent="1"/></xf>'
    // 12 header over numbers
    '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="right" vertical="center" wrapText="1"/></xf>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

Uint8List buildXlsx(List<XSheet> sheets, {required String title, required DateTime created}) {
  final files = <String, String>{
    '[Content_Types].xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        '${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
        '</Types>',
    '_rels/.rels':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '</Relationships>',
    'docProps/core.xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:title>${_esc(title)}</dc:title>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">${created.toUtc().toIso8601String().split('.').first}Z</dcterms:created>'
        '</cp:coreProperties>',
    'xl/workbook.xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<bookViews><workbookView activeTab="0"/></bookViews><sheets>'
        '${[for (final (i, s) in sheets.indexed) '<sheet name="${_esc(sheetName(s.name))}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
        '</sheets>${_filterNames(sheets)}</workbook>',
    'xl/_rels/workbook.xml.rels':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
        '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
    'xl/styles.xml': _styles,
    for (final (i, s) in sheets.indexed) 'xl/worksheets/sheet${i + 1}.xml': _sheetXml(s),
  };
  final archive = Archive();
  for (final e in files.entries) {
    archive.addFile(ArchiveFile.bytes(e.key, utf8.encode(e.value)));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// Excel keeps each sheet's filter range as a hidden name; without it the
/// filter still works but Excel "repairs" the file on some versions.
String _filterNames(List<XSheet> sheets) {
  final names = [
    for (final (i, s) in sheets.indexed)
      if (s.headerRow > 0 && s.rows.length > s.headerRow)
        '<definedName name="_xlnm._FilterDatabase" localSheetId="$i" hidden="1">'
            "'${_esc(sheetName(s.name)).replaceAll("'", "''")}'!${_absolute(_filterRef(s))}</definedName>",
  ];
  return names.isEmpty ? '' : '<definedNames>${names.join()}</definedNames>';
}

String _absolute(String ref) =>
    ref.split(':').map((p) => p.replaceAllMapped(RegExp(r'([A-Z]+)(\d+)'), (m) => '\$${m[1]}\$${m[2]}')).join(':');
