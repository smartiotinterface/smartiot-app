// lib/theme/app_theme.dart
// [SEC-FIX] google_fonts replaced with bundled local SpaceGrotesk font.
// Font files in assets/fonts/ — no network dependency.
// SmartIoT v8.0.0 — Full HD 3D Professional Theme
// ✅ Light mode: crisp white cards with 3-layer depth shadows
// ✅ Dark mode: rich navy glass with neon-trim highlights
// ✅ 3D-style shadow utilities, gradient buttons, inner-glow borders

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Purple Brand ───────────────────────────────────────────
  static const Color smartPurple      = Color(0xFF7C61D4);
  static const Color smartPurpleLight = Color(0xFFAB9FE0);
  static const Color smartPurpleDark  = Color(0xFF5A45B0);
  static const Color smartPurpleBg    = Color(0x1A7C61D4);

  // ── Accent ────────────────────────────────────────────────
  static const Color primaryBlue  = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent       = Color(0xFF0EA5E9);
  static const Color accentCyan   = Color(0xFF06B6D4);
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color danger       = Color(0xFFEF4444);

  // ── Dark Palette ──────────────────────────────────────────
  static const Color darkBg      = Color(0xFF060C1A);
  static const Color darkCard    = Color(0xFF0D1526);
  static const Color darkSurface = Color(0xFF131E34);
  static const Color darkBorder  = Color(0xFF1E3A5F);
  static const Color darkGlass   = Color(0x1A3B82F6);

  // ── Light Palette (HD upgrade) ────────────────────────────
  static const Color lightBg     = Color(0xFFF0EDFC);
  static const Color lightBg2    = Color(0xFFECF0FF);
  static const Color lightCard   = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4DEFF);
  static const Color lightText   = Color(0xFF1A1035);
  static const Color lightTextSub = Color(0xFF6B5FA0);

  // ── Gradients ─────────────────────────────────────────────
  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1526), Color(0xFF0A1628), Color(0xFF060D1A)],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B7FE8), Color(0xFF7C61D4), Color(0xFF5A45B0)],
  );

  static const Gradient purpleGradientH = LinearGradient(
    colors: [Color(0xFF8B71DC), Color(0xFF6B50C4)],
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF0EA5E9)],
  );

  static const Gradient accentGradientV = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E40AF), Color(0xFF0EA5E9)],
  );

  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
  );

  static const Gradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const Gradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  // ── 3D Shadow System ──────────────────────────────────────
  static List<BoxShadow> card3dLight = [
    const BoxShadow(color: Color(0x07000000), blurRadius: 2, offset: Offset(0, 1)),
    const BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
    BoxShadow(color: smartPurple.withValues(alpha: 0.09), blurRadius: 28, offset: const Offset(0, 10)),
  ];

  static List<BoxShadow> card3dDark = [
    const BoxShadow(color: Color(0x60000000), blurRadius: 16, offset: Offset(0, 6)),
    BoxShadow(color: smartPurple.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> buttonGlow = [
    BoxShadow(color: smartPurple.withValues(alpha: 0.42), blurRadius: 18, offset: const Offset(0, 6)),
    BoxShadow(color: smartPurple.withValues(alpha: 0.20), blurRadius: 32, offset: const Offset(0, 14)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x50000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0D3B82F6), blurRadius: 1, spreadRadius: 1),
  ];

  static List<BoxShadow> glowBlue({double intensity = 0.5}) => [
    BoxShadow(color: accent.withValues(alpha: intensity * 0.6), blurRadius: 24, spreadRadius: -4),
    BoxShadow(color: primaryLight.withValues(alpha: intensity * 0.3), blurRadius: 48, spreadRadius: -8),
  ];

  static List<BoxShadow> glowSuccess({double intensity = 0.5}) => [
    BoxShadow(color: success.withValues(alpha: intensity * 0.6), blurRadius: 20, spreadRadius: -4),
  ];

  static List<BoxShadow> glowDanger({double intensity = 0.5}) => [
    BoxShadow(color: danger.withValues(alpha: intensity * 0.6), blurRadius: 20, spreadRadius: -4),
  ];

  // ── Card Decorations ──────────────────────────────────────
  static BoxDecoration glassCard({required bool isDark, double radius = 20}) =>
      BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: isDark
            ? Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                right: BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 0.8),
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.45)),
              )
            : Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.95)),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.80), width: 0.8),
                right: const BorderSide(color: Color(0xFFE4DEFF), width: 0.8),
                bottom: const BorderSide(color: Color(0xFFD8D0FF)),
              ),
        boxShadow: isDark ? card3dDark : card3dLight,
      );

  static BoxDecoration glassDecoration({double borderRadius = 20, Color? borderColor, Color? bgColor}) =>
      BoxDecoration(
        color: bgColor ?? const Color(0x1A3B82F6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? const Color(0x333B82F6)),
      );

  static BoxDecoration cardDecoration({double borderRadius = 16, bool isDark = true, List<BoxShadow>? shadows}) =>
      BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: isDark ? const Color(0xFF1E3A5F) : lightBorder),
        boxShadow: shadows ?? (isDark ? card3dDark : card3dLight),
      );

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorSchemeSeed: smartPurple,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'SpaceGrotesk'),
        cardTheme: CardThemeData(
          color: darkCard, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E3A5F)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: smartPurple, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            elevation: 0,
            textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Color(0xFF1E3A5F)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: darkSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: smartPurple, width: 1.5)),
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIconColor: Colors.white38,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF1E3A5F), thickness: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkSurface,
          contentTextStyle: const TextStyle(fontFamily: 'SpaceGrotesk', color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 8,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white38),
          trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? smartPurple : Colors.white12),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? smartPurple : Colors.transparent),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Colors.white38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        listTileTheme: const ListTileThemeData(iconColor: Colors.white54, textColor: Colors.white),
      );

  // ── Light Theme (HD) ──────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: smartPurple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'SpaceGrotesk'),
        cardTheme: CardThemeData(
          color: lightCard, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: smartPurple, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            elevation: 0,
            textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DEFF))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DEFF))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: smartPurple, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: lightText,
          elevation: 0,
          titleTextStyle: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 17, fontWeight: FontWeight.w700, color: lightText),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: lightText,
          contentTextStyle: const TextStyle(fontFamily: 'SpaceGrotesk', color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 12,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFECE8FF), thickness: 1),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
          trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? smartPurple : const Color(0xFFCBC5E8)),
        ),
        listTileTheme: const ListTileThemeData(iconColor: smartPurple, textColor: lightText),
      );
}
