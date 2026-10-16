import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'shelf_physics.dart';

/// Draws its child flexed: the image is cut into horizontal bands and each
/// band is sheared sideways so that height t moves by
/// [bend] × width × [Feel.profile] (t), piecewise linear between bands.
/// A photo has no separate parts, so this is how a laptop lid rocks on its
/// hinge or a vacuum whips. At rest (bend ≈ 0) the child is painted once,
/// untouched. Painting and hit testing stay in the child's own box.
///
/// The child must paint without layers of its own (no ShaderMask, Opacity
/// layer or RepaintBoundary inside): a layer can only be in the tree once, so
/// all but the last band would come out empty. Put such effects outside.
class Bend extends SingleChildRenderObjectWidget {
  const Bend({super.key, required this.bend, required this.feel, super.child});
  final double bend;
  final Feel feel;

  @override
  RenderBend createRenderObject(BuildContext context) => RenderBend(bend, feel);

  @override
  void updateRenderObject(BuildContext context, RenderBend renderObject) => renderObject
    ..bend = bend
    ..feel = feel;
}

class RenderBend extends RenderProxyBox {
  RenderBend(this._bend, this._feel);

  /// Bands per product; 14 keeps a whip curve smooth at 100 pt tall.
  static const bands = 14;

  double _bend;
  set bend(double v) {
    if (v == _bend) return;
    _bend = v;
    markNeedsPaint();
  }

  Feel _feel;
  set feel(Feel v) {
    if (identical(v, _feel)) return;
    _feel = v;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_bend.abs() < .002) {
      context.paintChild(child, offset);
      return;
    }
    final w = size.width, h = size.height;
    final band = h / bands;
    for (var i = 0; i < bands; i++) {
      // Band i counted from the bottom. Each band is sheared, not just
      // shifted: its bottom edge moves by the profile at its bottom and its
      // top edge by the profile at its top, so neighbouring bands meet
      // exactly and the outline stays one continuous curve. (16 Oct: plain
      // shifts made a visible staircase on every edge while an item swung.)
      final o0 = _bend * w * _feel.profile(i / bands);
      final o1 = _bend * w * _feel.profile((i + 1) / bands);
      final bottom = h - i * band;
      final top = h - (i + 1) * band;
      // x' = x + a + k·y, with x' − x = o0 at the bottom and o1 at the top.
      final k = (o0 - o1) / band;
      final a = o0 - k * bottom;
      final shear = Matrix4.identity()
        ..setEntry(0, 1, k)
        ..setEntry(0, 3, a);
      // Hard-edged clips that share an edge split the pixels between them:
      // no gap and no pixel drawn twice (an overlap drew darker seams on
      // the soft edges of a cut-out photo). The outer bands reach past the
      // box for anything the child paints outside it.
      final clip = Rect.fromLTRB(-w, i == bands - 1 ? -h : top, w * 2, i == 0 ? h * 2 : bottom);
      context.pushTransform(
        needsCompositing,
        offset,
        shear,
        (c, o) => c.pushClipRect(needsCompositing, o, clip, (c, o) => c.paintChild(child, o)),
      );
    }
  }
}
