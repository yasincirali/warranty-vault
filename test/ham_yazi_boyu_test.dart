import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md: screens take colour and type from tokens, never raw
/// `fontSize:` / `Color(0x…)`. Nothing checked it until 28 Oct, when 8 raw
/// sizes had crept in; they now live in `VText`. The PDF builds its own
/// styles (the `pdf` package has no theme), the theme is where tokens are
/// defined, generated code is not ours.
void main() {
  test('no raw fontSize or Color(0x...) in lib/ outside the theme', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.startsWith('lib/core/theme/') || path.contains('/generated/') || path.endsWith('pdf_export.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('fontSize:') || line.contains('Color(0x')) hits.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    expect(hits, isEmpty, reason: 'name the style in VText / the colour in VColors');
  });
}
