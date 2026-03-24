import 'package:flutter/material.dart';

class AppTheme {
  // === Primary: Orange from app icon ===
  static const Color orange = Color(0xFFE8763A);
  static const Color orangeLight = Color(0xFFF2A06A);
  static const Color orangeSoft = Color(0xFFFCE8DA);

  // === Warm cream base (inspired by TravelLanguage) ===
  static const Color cream = Color(0xFFF6F1EA);
  static const Color warmWhite = Color(0xFFFFFDF9);
  static const Color parchment = Color(0xFFE8DED0);

  // === Ink text colors ===
  static const Color ink = Color(0xFF2C2420);
  static const Color inkLight = Color(0xFF6B5E56);
  static const Color inkFaint = Color(0xFFA89B91);

  // === Accent for category chart (muted, literary) ===
  static const Color stampRed = Color(0xFFD44B3C);
  static const Color tagBlue = Color(0xFF4A7B96);
  static const Color moss = Color(0xFF7A9A6D);
  static const Color plum = Color(0xFF9B7BAA);
  static const Color amber = Color(0xFFCDA64F);
  static const Color slate = Color(0xFF7E8B92);

  // === No-budget / infinity ===
  static const Color infinity = Color(0xFF9BB5C4);     // 霧藍
  static const Color infinitySoft = Color(0xFFDFEBF0);  // 淡霧藍

  // === Shadows ===
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.06),
          offset: const Offset(0, 2),
          blurRadius: 12,
        ),
        BoxShadow(
          color: ink.withValues(alpha: 0.03),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        brightness: Brightness.light,
        surface: cream,
        onSurface: ink,
      ).copyWith(
        primary: orange,
        onPrimary: Colors.white,
        secondary: inkLight,
        tertiary: orangeLight,
      ),
      fontFamily: null, // use system default for CJK support
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cream,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: warmWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: parchment.withValues(alpha: 0.6)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: BorderSide(color: orange.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: parchment),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: parchment),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        labelStyle: const TextStyle(color: inkLight),
        hintStyle: const TextStyle(color: inkFaint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: parchment.withValues(alpha: 0.7),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: warmWhite,
        selectedColor: orange,
        side: BorderSide(color: parchment),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: warmWhite,
        indicatorColor: orangeSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: inkFaint,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: orange, size: 24);
          }
          return const IconThemeData(color: inkFaint, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: warmWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return orange;
          return inkFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return orangeSoft;
          return parchment;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: orange,
        linearTrackColor: Color(0xFFEDE6DC),
      ),
    );
  }
}
