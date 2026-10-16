import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'shelf_physics.dart';

/// Draws its child flexed: the image is cut into horizontal bands and each
/// band is shifted sideways by [bend] × width × [Feel.profile] of its height.
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
      // Band i counted from the bottom; its middle sets the shift.
      final t = (i + .5) / bands;
      final dx = _bend * w * _feel.profile(t);
      final top = h - (i + 1) * band;
      // Half a pixel of overlap hides seams between bands.
      final clip = Rect.fromLTWH(-w, top - .5, w * 3, band + 1);
      context.pushClipRect(needsCompositing, offset + Offset(dx, 0), clip, (c, o) => c.paintChild(child, o));
    }
  }
}
