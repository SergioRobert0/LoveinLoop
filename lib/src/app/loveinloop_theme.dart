import 'package:flutter/material.dart';

abstract final class LoveInLoopColors {
  static const primary = Color(0xffbe123c);
  static const primaryDark = Color(0xff4c1024);
  static const accent = Color(0xff0f766e);
  static const gold = Color(0xffd97706);
  static const background = Color(0xfffffaf7);
  static const surface = Color(0xffffffff);
  static const surfaceMuted = Color(0xfffff1f3);
  static const text = Color(0xff2f1f25);
  static const textMuted = Color(0xff7a4b5b);
  static const border = Color(0xffffc9d4);
  static const danger = Color(0xffa4133c);
}

ThemeData buildLoveInLoopTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: LoveInLoopColors.primary,
      brightness: Brightness.light,
      primary: LoveInLoopColors.primary,
      secondary: LoveInLoopColors.accent,
      tertiary: LoveInLoopColors.gold,
      surface: LoveInLoopColors.surface,
      error: LoveInLoopColors.danger,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: LoveInLoopColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: LoveInLoopColors.background,
      foregroundColor: LoveInLoopColors.primaryDark,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: LoveInLoopColors.primaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: LoveInLoopColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: LoveInLoopColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LoveInLoopColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LoveInLoopColors.primary,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: LoveInLoopColors.primary),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LoveInLoopColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: LoveInLoopColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LoveInLoopColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoveInLoopColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoveInLoopColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoveInLoopColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoveInLoopColors.danger),
      ),
      labelStyle: const TextStyle(color: LoveInLoopColors.textMuted),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: LoveInLoopColors.primaryDark,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: LoveInLoopColors.surface,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: LoveInLoopColors.text,
      displayColor: LoveInLoopColors.primaryDark,
    ),
  );
}
