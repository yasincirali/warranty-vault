import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/ui/time_rule.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';

import 'home_smoke_test.dart' show app;

void main() {
  testWidgets('the product page draws each protection once', (t) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Sony WH-1000XM5').first);
    await t.pumpAndSettle();
    // The answer card keeps its number and sentence; the period is drawn
    // only as the bands, one per protection.
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(TimeRule), findsNothing);
    expect(find.byType(TimeBand), findsNWidgets(3));
    // The card's protection is the bold row and still says, for screen
    // readers, how far the period has run.
    final title = t.widget<Text>(find.text('Return window').last);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(find.bySemanticsLabel(RegExp('of the period has passed')), findsOneWidget);
    semantics.dispose();
  });

  for (final scale in [1.0, 2.0, 3.1]) {
    testWidgets('home title stays one line at ${scale}x text', (t) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      for (final store in [null, MemoryVaultStore()]) {
        await t.pumpWidget(app(textScale: scale, store: store));
        await t.pumpAndSettle();
        // The test font is far wider than the real one, so the word's own
        // line count is checked on the store screenshots; here the two
        // decisions that keep it whole: the title's scale is capped at 2×,
        // and from 1.6× the buttons sit on their own row under it.
        final title = find.text('My things');
        final scaler = MediaQuery.textScalerOf(t.element(title));
        expect(scaler.scale(1), scale < 2 ? scale : 2);
        final settings = t.getTopLeft(find.byTooltip('Settings'));
        if (scale >= 1.6) {
          expect(settings.dy, greaterThan(t.getTopLeft(title).dy + t.getSize(title).height - 1));
        } else {
          expect(settings.dy, lessThan(t.getTopLeft(title).dy + t.getSize(title).height));
        }
        expect(t.takeException(), isNull);
      }
    });
  }
}
