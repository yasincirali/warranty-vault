import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/theme/tokens.dart';

import 'home_smoke_test.dart' show app;

void main() {
  test('dark cabinet: the wall stands off the page and light falls down it', () {
    const d = VColors.dark;
    // Black headphones, phones and TVs melted into a wall a hair off the
    // page (#17181B on #111214). The wall needs a visible step.
    expect(d.wall.computeLuminance() - d.background.computeLuminance(), greaterThan(.008));
    expect(d.wallLight.a, greaterThan(0));
    // The light theme is unchanged: no added light.
    expect(VColors.light.wallLight.a, 0);
  });

  testWidgets('home says the count once; the cabinet start stays a heading for screen readers', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.textContaining('All ·'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'All · \d')),
      findsOneWidget,
    );
    final node = t.getSemantics(find.bySemanticsLabel(RegExp(r'All · \d')));
    expect(node.flagsCollection.isHeader, isTrue);
    semantics.dispose();
  });
}
