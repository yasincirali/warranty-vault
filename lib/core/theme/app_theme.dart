import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? VColors.light : VColors.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.background,
    ),
    scaffoldBackgroundColor: c.background,
    // Instrument Sans ships as an asset once the font licence is added;
    // until then the platform font keeps text crisp and Dynamic Type works.
  );
  return base.copyWith(
    extensions: [c, VText(c.text)],
    dividerColor: c.divider,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size.fromHeight(VSize.button),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // Fields are white cards on the paper background, like everything else
    // the user owns in the app. Focus turns the hairline into a 2-pt ink
    // edge and the label ink: one clear "you are here" (the lift shadow is
    // added by VFieldLift). Material animates both border and label.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      // A pointer hovering (iPad, web preview) must not grey the field out:
      // grey reads as disabled here.
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.lg),
      labelStyle: TextStyle(color: c.textSecondary),
      floatingLabelStyle: TextStyle(color: c.text, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
