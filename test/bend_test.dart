import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/cabinet/bend.dart';
import 'package:warranty_vault/features/cabinet/shelf_physics.dart';

/// Left edge of a 4-px vertical bar, row by row, as [Bend] draws it.
Future<List<int>> _barEdges(WidgetTester t, double bend, Feel feel) async {
  final key = GlobalKey();
  await t.binding.setSurfaceSize(const Size(200, 160));
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 200,
            height: 140,
            child: Bend(
              bend: bend,
              feel: feel,
              child: const Center(
                child: SizedBox(width: 4, height: 140, child: ColoredBox(color: Color(0xFF000000))),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final edges = <int>[];
  await t.runAsync(() async {
    final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
    final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    for (var y = 0; y < img.height; y++) {
      for (var x = 0; x < img.width; x++) {
        if (px.getUint8((y * img.width + x) * 4 + 3) > 128) {
          edges.add(x);
          break;
        }
      }
    }
  });
  return edges;
}

void main() {
  // 16 Oct: shifting whole bands drew a staircase on every edge while an item
  // swung. The flexed outline must be one continuous line: no row may jump
  // sideways more than the curve's own slope allows, and no row may be lost.
  for (final (name, feel) in [('whip', Feel.vacuum), ('hinge', Feel.laptop), ('stiff', Feel.phone)]) {
    testWidgets('a flexed $name edge is continuous, without steps or gaps', (t) async {
      final edges = await _barEdges(t, .3, feel);
      expect(edges.length, 140, reason: 'every row of the bar is still drawn');
      var jump = 0;
      for (var i = 1; i < edges.length; i++) {
        jump = (edges[i] - edges[i - 1]).abs() > jump ? (edges[i] - edges[i - 1]).abs() : jump;
      }
      expect(jump, lessThanOrEqualTo(1));
      expect((edges.first - edges.last).abs(), greaterThan(30), reason: 'and it really bends');
    });
  }

  testWidgets('at rest the child is drawn untouched', (t) async {
    final edges = await _barEdges(t, 0, Feel.vacuum);
    expect(edges.toSet(), {98});
  });
}
