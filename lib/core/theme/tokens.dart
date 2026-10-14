import 'package:flutter/material.dart';

/// Design tokens of the C2 "Vitrin" direction.
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
  final Color adviceSurface;
  final Color adviceBorder;
  final Color adviceTitle;

  // Text colours were picked for ≥4.5:1 on their surface in each theme.
  static const light = VColors(
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE2E5EA),
    divider: Color(0xFFEEF0F3),
    text: Color(0xFF14171F),
    textSecondary: Color(0xFF565D6B),
    muted: Color(0xFF6B7280),
    accent: Color(0xFF2346FF),
    onAccent: Color(0xFFFFFFFF),
    deadline: Color(0xFF9A4A00),
    deadlineSurface: Color(0xFFFFF1D6),
    tile: Color(0xFFECEEF2),
    adviceSurface: Color(0xFFF3F5FF),
    adviceBorder: Color(0xFFC9D2FF),
    adviceTitle: Color(0xFF2A3590),
  );

  static const dark = VColors(
    background: Color(0xFF0F1115),
    surface: Color(0xFF181B21),
    border: Color(0xFF2A2F38),
    divider: Color(0xFF22262E),
    text: Color(0xFFF1F3F6),
    textSecondary: Color(0xFFA9B0BC),
    muted: Color(0xFF8A919D),
    accent: Color(0xFF8DA2FF),
    onAccent: Color(0xFF0F1115),
    deadline: Color(0xFFFFB866),
    deadlineSurface: Color(0xFF3A2A12),
    tile: Color(0xFF22262E),
    adviceSurface: Color(0xFF1A1F33),
    adviceBorder: Color(0xFF34407A),
    adviceTitle: Color(0xFFB9C4FF),
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
  TextStyle get bigNumber => TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: base);
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
