import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/theme/tokens.dart';
import 'package:warranty_vault/core/ui/brand_mark.dart';

Widget _host({required bool ready, bool still = false}) => MediaQuery(
  data: MediaQueryData(size: const Size(393, 852), disableAnimations: still),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: BrandIntro(ready: ready, label: 'Yükleniyor', child: const Text('raf')),
  ),
);

bool _covered(WidgetTester t) =>
    find.byWidgetPredicate((w) => w is ColoredBox && w.color == VBrand.splash).evaluate().isNotEmpty;

void main() {
  test('the loop starts and ends on the splash logo, so the hand-over has no jump', () {
    for (final t in [0.0, 1.0]) {
      final p = MarkPose.at(t);
      expect(p.receipt, 1);
      expect(p.lines, everyElement(1));
      expect(p.shield, closeTo(1, 1e-9));
      expect(p.check, 1);
    }
    // Midway the receipt really goes back into the tray.
    expect(MarkPose.at(.32).receipt, 0);
  });

  testWidgets('plays one full loop even when the cabinet is already there', (t) async {
    await t.pumpWidget(_host(ready: true));
    await t.pump(VMotion.brandCycle * .8);
    expect(_covered(t), isTrue);
    await t.pumpAndSettle();
    expect(_covered(t), isFalse);
    expect(find.text('raf'), findsOneWidget);
  });

  testWidgets('keeps looping until ready, then fades into the app', (t) async {
    await t.pumpWidget(_host(ready: false));
    await t.pump(VMotion.brandCycle * 3);
    expect(_covered(t), isTrue);
    await t.pumpWidget(_host(ready: true));
    await t.pumpAndSettle();
    expect(_covered(t), isFalse);
  });

  testWidgets('reduce motion: no loop, the app shows as soon as it is ready', (t) async {
    await t.pumpWidget(_host(ready: false, still: true));
    expect(_covered(t), isTrue);
    expect(t.hasRunningAnimations, isFalse);
    await t.pumpWidget(_host(ready: true, still: true));
    await t.pump();
    expect(_covered(t), isFalse);
  });

  testWidgets('screen readers hear that it is loading', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(ready: false));
    expect(find.bySemanticsLabel('Yükleniyor'), findsOneWidget);
    h.dispose();
    await t.pumpWidget(_host(ready: true));
    await t.pumpAndSettle();
  });
}
