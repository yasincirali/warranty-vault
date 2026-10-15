import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Where each part of the logo is during the loop; 1 everywhere = the logo
/// exactly as on the icon and the system splash.
@immutable
class MarkPose {
  const MarkPose({this.receipt = 1, this.lines = const [1, 1, 1, 1], this.shield = 1, this.check = 1});

  /// 0 = sunk into the tray, 1 = standing up.
  final double receipt;

  /// How far each printed line (three ink, one amber) has been written.
  final List<double> lines;

  /// 0 = gone, 1 = stamped in place (may overshoot while it lands).
  final double shield;

  /// How much of the check has been drawn.
  final double check;

  static const rest = MarkPose();

  /// The loop starts and ends at [rest], so it hands over from the splash
  /// without a jump and can repeat while the cabinet is still loading.
  /// Story: the shield lifts off, the receipt goes back into its tray and
  /// prints out again line by line, the shield stamps it and ticks it.
  factory MarkPose.at(double t) {
    double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    final away = Curves.easeInCubic.transform(seg(0, .2));
    final sink = Curves.easeInOutCubic.transform(seg(.08, .32));
    final rise = Curves.easeOutCubic.transform(seg(.32, .6));
    final stamp = Curves.easeOutBack.transform(seg(.6, .76));
    final tick = Curves.easeOutCubic.transform(seg(.74, .9));
    final writing = t >= .32 && t < .9;
    return MarkPose(
      receipt: t < .32 ? 1 - sink : rise,
      lines: [
        for (var i = 0; i < 4; i++) writing ? Curves.easeOutCubic.transform(seg(.42 + i * .06, .56 + i * .06)) : 1,
      ],
      shield: t < .6 ? 1 - away : stamp,
      check: t < .6 ? 1 - away : tick,
    );
  }
}

/// The logo (icon E, "Fiş ve kalkan") drawn in code, in the 1024 space of
/// store_listing/ikon/isaret.svg, so it can move. Transparent background:
/// the caller supplies the brand green.
class BrandMarkPainter extends CustomPainter {
  BrandMarkPainter(this.pose);
  final MarkPose pose;

  static final _receipt = () {
    final p = Path()..moveTo(300, 290);
    const teeth = 10, w = 34.0;
    for (var i = 0; i < teeth; i++) {
      p
        ..lineTo(300 + w * (i + .5), 264)
        ..lineTo(300 + w * (i + 1), 290);
    }
    return p
      ..lineTo(640, 742)
      ..lineTo(300, 742)
      ..close();
  }();
  static final _shield = Path()
    ..moveTo(650, 512)
    ..lineTo(752, 548)
    ..lineTo(752, 626)
    ..cubicTo(752, 700, 708, 744, 650, 770)
    ..cubicTo(592, 744, 548, 700, 548, 626)
    ..lineTo(548, 548)
    ..close();
  static final PathMetric _check =
      (Path()
            ..moveTo(604, 640)
            ..relativeLineTo(34, 34)
            ..relativeLineTo(64, -74))
          .computeMetrics()
          .first;
  static final _tray = Path()
    ..moveTo(232, 742)
    ..lineTo(792, 742)
    ..cubicTo(800, 742, 804, 750, 800, 760)
    ..cubicTo(790, 790, 768, 804, 740, 804)
    ..lineTo(284, 804)
    ..cubicTo(256, 804, 234, 790, 224, 760)
    ..cubicTo(220, 750, 224, 742, 232, 742)
    ..close();
  static const _lines = [(380.0, 230.0), (450.0, 170.0), (520.0, 130.0), (610.0, 110.0)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 1024, size.height / 1024)
      // Same group transform as the SVG: the mark fills the icon a bit more.
      ..translate(512, 534)
      ..scale(1.22)
      ..translate(-512, -534);

    final fill = Paint()..isAntiAlias = true;

    // Receipt: clipped at the tray's lip so it seems to come out of it.
    canvas
      ..save()
      ..clipRect(const Rect.fromLTRB(0, 0, 1024, 742));
    canvas.translate(0, (1 - pose.receipt) * 480);
    canvas.drawPath(_receipt, fill..color = VBrand.paper);
    for (var i = 0; i < _lines.length; i++) {
      final k = pose.lines[i];
      if (k <= 0) continue;
      final (y, w) = _lines[i];
      final width = math.max(34.0, w * k);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(350, y, width, 34), const Radius.circular(17)),
        fill..color = (i == 3 ? VBrand.amber : VBrand.ink).withValues(alpha: k.clamp(0.0, 1.0)),
      );
    }
    canvas.restore();

    // Shield: stamps down from slightly above, scaled about its centre.
    if (pose.shield > 0) {
      final s = pose.shield;
      canvas
        ..save()
        ..translate(650, 640 - (1 - s.clamp(0.0, 1.0)) * 60)
        ..scale(s)
        ..translate(-650, -640);
      final a = s.clamp(0.0, 1.0);
      canvas.drawPath(_shield, fill..color = VBrand.shield.withValues(alpha: a));
      canvas.drawPath(
        _shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round
          ..color = VBrand.shieldEdge.withValues(alpha: a),
      );
      if (pose.check > 0) {
        canvas.drawPath(
          _check.extractPath(0, _check.length * pose.check.clamp(0.0, 1.0)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 28
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = VBrand.amber,
        );
      }
      canvas.restore();
    }

    canvas.drawPath(_tray, fill..color = VBrand.paper);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) => true;
}

/// Size of the mark on the system splash (LaunchImage, `acilis_isareti`):
/// the intro starts at exactly this size and place.
const kSplashMark = 160.0;

/// What the user sees right after the splash: the splash itself comes alive.
/// The mark plays at least one loop (the "fancy loader" asked for), keeps
/// looping while [ready] is false, then lifts slightly and fades into the
/// app. It sits above the navigator, so whatever screen opens first is
/// already built underneath.
///
/// Reduce motion: no loop; the still mark stays until [ready] and then goes
/// at once.
class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.ready, required this.label, required this.child});
  final bool ready;

  /// Read by screen readers while the intro is up ("Loading").
  final String label;
  final Widget child;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> with TickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this, duration: VMotion.brandCycle)..addStatusListener(_onLoop);
  late final _exit = AnimationController(vsync: this, duration: VMotion.enter)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _gone = true);
    });
  bool _gone = false;
  bool _started = false;

  bool get _still => MediaQuery.of(context).disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_still) {
      if (widget.ready) _gone = true;
    } else {
      _loop.forward();
    }
  }

  void _onLoop(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    if (widget.ready) {
      _exit.forward();
    } else {
      _loop.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(BrandIntro old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready && _still) setState(() => _gone = true);
  }

  @override
  void dispose() {
    _loop.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: AnimatedBuilder(
              animation: Listenable.merge([_loop, _exit]),
              builder: (context, _) {
                final out = Curves.easeInCubic.transform(_exit.value);
                return Opacity(
                  opacity: 1 - out,
                  child: ColoredBox(
                    color: VBrand.splash,
                    child: Center(
                      child: Semantics(
                        label: widget.label,
                        liveRegion: true,
                        child: Transform.scale(
                          scale: 1 + .08 * out,
                          child: SizedBox.square(
                            dimension: kSplashMark,
                            child: CustomPaint(
                              painter: BrandMarkPainter(_still ? MarkPose.rest : MarkPose.at(_loop.value)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The same loop in a small app-icon tile, for waits inside the app
/// (an item opening, a receipt being read, a photo being cut out).
/// Reduce motion: the tile only breathes.
class VLoader extends StatefulWidget {
  const VLoader({super.key, required this.label, this.size = 64});
  final String label;
  final double size;

  @override
  State<VLoader> createState() => _VLoaderState();
}

class _VLoaderState extends State<VLoader> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this);
  bool? _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still == _still) return;
    _still = still;
    if (still) {
      _c
        ..duration = VMotion.brandPulse
        ..repeat(reverse: true);
    } else {
      _c
        ..duration = VMotion.brandCycle
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Opacity(
            opacity: _still! ? .55 + .45 * _c.value : 1,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: VBrand.splash,
                // iOS icon corner: ~22% of the side.
                borderRadius: BorderRadius.circular(widget.size * .225),
              ),
              child: CustomPaint(painter: BrandMarkPainter(_still! ? MarkPose.rest : MarkPose.at(_c.value))),
            ),
          ),
        ),
      ),
    );
  }
}
