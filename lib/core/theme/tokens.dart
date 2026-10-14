import 'package:flutter/material.dart';

/// Design tokens of the C2 "Vitrin" direction, after the four review rounds
/// (canvas boards Tur1–Tur4).
///
/// Rule of the design: colour carries meaning, never decoration.
/// - [accent] only on the primary action of a screen.
/// - [deadline] only for a protection that ends within 30 days.
/// - [muted] for what has ended.
/// Screens never write raw colours, font sizes or paddings; they read these.
@immutable
class VColors extends ThemeExtension<VColors> {
  const VColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.deadline,
    required this.deadlineSurface,
    required this.tile,
    required this.track,
    required this.adviceSurface,
    required this.adviceBorder,
    required this.adviceTitle,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color divider;
  final Color text;
  final Color textSecondary;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color deadline;
  final Color deadlineSurface;
  final Color tile;

  /// Empty part of the time rule.
  final Color track;
  final Color adviceSurface;
  final Color adviceBorder;
  final Color adviceTitle;

  // Text colours were picked for ≥4.5:1 on their surface in each theme.
  //
  // Review round 3 (2026-10-14): the accent is ink, not blue. With a blue
  // accent the primary button and the amber deadline competed for the eye;
  // now amber is the only hue on screen, so a deadline is the first thing
  // seen. Amber also reads as neither gain nor loss in any market (red/green
  // flip meaning between cultures). The warm paper background is the
  // receipt metaphor doing a job: less glare than #FFF and white cards
  // separate from it without shadows.
  static const light = VColors(
    background: Color(0xFFF4F2EC),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE4E0D6),
    divider: Color(0xFFEEEBE3),
    text: Color(0xFF16181D),
    textSecondary: Color(0xFF575B64),
    muted: Color(0xFF6E727A),
    accent: Color(0xFF16181D),
    onAccent: Color(0xFFFFFFFF),
    deadline: Color(0xFFA04E00),
    deadlineSurface: Color(0xFFFFF1D6),
    tile: Color(0xFFECE8DF),
    track: Color(0xFFE4E0D6),
    adviceSurface: Color(0xFFFFFFFF),
    adviceBorder: Color(0xFF16181D),
    adviceTitle: Color(0xFF16181D),
  );

  static const dark = VColors(
    background: Color(0xFF111214),
    surface: Color(0xFF1B1C20),
    border: Color(0xFF2B2D33),
    divider: Color(0xFF26282D),
    text: Color(0xFFF2F1EE),
    textSecondary: Color(0xFFB4B6BC),
    muted: Color(0xFF8E9097),
    accent: Color(0xFFF2F1EE),
    onAccent: Color(0xFF111214),
    deadline: Color(0xFFFFB45C),
    deadlineSurface: Color(0xFF3A2A12),
    tile: Color(0xFF24262B),
    track: Color(0xFF2E3036),
    adviceSurface: Color(0xFF1B1C20),
    adviceBorder: Color(0xFFF2F1EE),
    adviceTitle: Color(0xFFF2F1EE),
  );

  @override
  VColors copyWith() => this;

  @override
  VColors lerp(VColors? other, double t) => t < .5 ? this : (other ?? this);
}

/// 4-pt spacing scale.
abstract final class VSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

abstract final class VRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 18.0;
  static const sheet = 24.0;
}

/// HIG: every tappable thing is at least 44 pt.
abstract final class VSize {
  static const minTap = 44.0;
  static const button = 52.0;
}

@immutable
class VText extends ThemeExtension<VText> {
  const VText(this.base);
  final Color base;

  TextStyle get display =>
      TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -.6, color: base);
  TextStyle get title =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.2, color: base);
  /// The "28" of "28 days left": number big, unit small (round 3).
  TextStyle get bigNumber => TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -2,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: base);
  TextStyle get bigUnit => TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: base);
  TextStyle get body => TextStyle(fontSize: 15.5, height: 1.45, color: base);
  TextStyle get label => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base);
  TextStyle get small => TextStyle(fontSize: 14, height: 1.35, color: base);
  TextStyle get section =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: .1, color: base);

  @override
  VText copyWith() => this;

  @override
  VText lerp(VText? other, double t) => t < .5 ? this : (other ?? this);
}

extension VThemeX on BuildContext {
  VColors get c => Theme.of(this).extension<VColors>()!;
  VText get t => Theme.of(this).extension<VText>()!;
}

/// Motion durations. Read through [VMotion.of] so "reduce motion" turns
/// every animation into an instant change in one place.
abstract final class VMotion {
  /// The time rule filling up to today when an item opens.
  static const ruleFill = Duration(milliseconds: 400);

  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : d;
}
