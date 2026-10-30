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
    required this.lift,
    required this.wall,
    required this.plankTop,
    required this.plankFront,
    required this.shade,
    required this.wallLight,
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

  /// Shadow of something picked up: a product off its shelf, a field in
  /// focus. One shadow colour so "lifted" means one thing.
  final Color lift;

  /// The cabinet (round 6, 2026-10-16): one object with depth instead of
  /// stripes across the page. Light comes from above: the back [wall] is a
  /// step darker than the page, a plank's [plankTop] catches the light and
  /// its [plankFront] edge is in shade. [shade] is the base of every cast
  /// shadow inside the cabinet, always used with a low alpha.
  final Color wall;
  final Color plankTop;
  final Color plankFront;
  final Color shade;

  /// Light falling down the back wall under each plank. Only the dark theme
  /// has it (Rafım Ar-Ge 29 Oct): there the wall sat a hair off the page and
  /// black headphones, phones and TVs melted into it. A little light from
  /// above gives their silhouettes an edge; in the light theme the page
  /// already does that, so it stays transparent.
  final Color wallLight;

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
    lift: Color(0x2916181D),
    wall: Color(0xFFEBE7DD),
    plankTop: Color(0xFFFBFAF6),
    plankFront: Color(0xFFE2DCCF),
    shade: Color(0xFF2A2418),
    wallLight: Color(0x00FFFFFF),
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
    lift: Color(0x8C000000),
    // A step lighter than it was (#17181B, 29 Oct): dark products need a
    // wall they can stand out against.
    wall: Color(0xFF212328),
    plankTop: Color(0xFF34363C),
    plankFront: Color(0xFF26282D),
    shade: Color(0xFF000000),
    wallLight: Color(0x14FFFFFF),
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
/// The logo's own colours (store_listing/ikon/ikon.svg). They belong to the
/// brand mark, not to the UI: the same in light and dark, used only by
/// [BrandMark] and the launch screens. [splash] is also the iOS
/// LaunchScreen.storyboard and Android `marka_zemin` colour, so the hand-over
/// from the system splash to Flutter shows no seam; change them together.
abstract final class VBrand {
  static const splash = Color(0xFF0F2E28);
  static const paper = Color(0xFFF3EBDD);
  static const ink = Color(0xFF0E2A23);
  static const amber = Color(0xFFE8A23A);
  static const shield = Color(0xFF123A31);
  static const shieldEdge = Color(0xFF3B7A66);
}

abstract final class VSize {
  static const minTap = 44.0;
  static const button = 52.0;
}

@immutable
class VText extends ThemeExtension<VText> {
  const VText(this.base);
  final Color base;

  TextStyle get display => TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -.6, color: base);
  TextStyle get title => TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.2, color: base);

  /// The "28" of "28 days left": number big, unit small (round 3).
  TextStyle get bigNumber => TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: base,
  );
  TextStyle get bigUnit => TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: base);
  TextStyle get body => TextStyle(fontSize: 15.5, height: 1.45, color: base);
  TextStyle get label => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base);
  TextStyle get small => TextStyle(fontSize: 14, height: 1.35, color: base);
  TextStyle get section => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: .1, color: base);

  // Sizes that screens used to write by hand (Rafım Ar-Ge 28 Oct): named
  // here so Dynamic Type and any later type change happen in one file.
  // `ham_yazi_boyu_test` keeps raw `fontSize:` out of lib/ screens.

  /// "Kasada göster": the product name read across a counter.
  TextStyle get counterName => display.copyWith(fontSize: 28);

  /// "Kasada göster": a fact (date, amount, serial) the clerk checks.
  TextStyle get counterFact => label.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// One sentence that must be read, a step above body.
  TextStyle get bodyLarge => body.copyWith(fontSize: 16);

  /// Captions under a time rule or a list row.
  TextStyle get caption => small.copyWith(fontSize: 12.5);

  /// Deadline tag on a plank and the label-maker tape.
  TextStyle get tag => TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: base);

  /// A product's name tag on its shelf (fixed size, not scaled).
  TextStyle get micro => small.copyWith(fontSize: 10, height: 1.2, fontWeight: FontWeight.w600);

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

  /// State changes in controls: focus ring, checkmark, a field's done tick.
  static const quick = Duration(milliseconds: 180);

  /// Something moving across the screen (a segment thumb).
  static const slide = Duration(milliseconds: 220);

  /// Things entering a screen (form rows, a picked photo).
  static const enter = Duration(milliseconds: 260);

  /// Gap between rows entering one after another.
  static const stagger = Duration(milliseconds: 40);

  /// One loop of the brand mark: the receipt goes back into its tray, prints
  /// out again and the shield stamps it. Long enough to read as one gesture.
  static const brandCycle = Duration(milliseconds: 1400);

  /// Reduce-motion stand-in for the loop: the mark only breathes (a fade).
  static const brandPulse = Duration(milliseconds: 900);

  static Duration of(BuildContext context, Duration d) => MediaQuery.of(context).disableAnimations ? Duration.zero : d;
}
