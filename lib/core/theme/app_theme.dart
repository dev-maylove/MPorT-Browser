import 'package:flutter/material.dart';

/// Design tokens from MandalaNet / MPorT v2.0.1 (public/assets/css/style.css)
class AppTheme {
  // Backgrounds
  static const bgDeep = Color(0xFF06080F);
  static const bgPrimary = Color(0xFF0A0D17);
  static const bgCard = Color(0xFF111627);
  static const bgGlass = Color(0xA60F1322); // rgba(15,19,34,0.65)

  // Borders
  static const borderSubtle = Color(0x0FFFFFFF); // ~6% white
  static const borderGlow = Color(0x4000D4FF);

  // Text
  static const textPrimary = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFFA8AFC2);
  static const textMuted = Color(0xFF6B7288);

  // Accents (brand)
  static const cyanNeon = Color(0xFF00E5FF);
  static const cyanGlow = Color(0x8000E5FF);
  static const greenStatus = Color(0xFF00E676);
  static const blueAccent = Color(0xFF4D7CFF);
  static const purpleAccent = Color(0xFFA855F7);
  static const danger = Color(0xFFE04060);

  // Legacy aliases used across older screens
  static const green = cyanNeon;
  static const dark = bgDeep;
  static const panel = bgCard;
  static const panel2 = bgPrimary;

  static const radiusMd = 16.0;
  static const radiusLg = 22.0;
  static const radiusXl = 28.0;

  static const gradientAi = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanNeon, blueAccent, purpleAccent],
    stops: [0.0, 0.4, 1.0],
  );

  static const gradientCyanPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3EE), Color(0xFFA78BFA)],
  );

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: cyanNeon,
      onPrimary: bgDeep,
      secondary: blueAccent,
      tertiary: purpleAccent,
      surface: bgCard,
      onSurface: textPrimary,
      error: danger,
      outline: borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgDeep,
      cardColor: bgCard,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: textSecondary),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDeep,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: bgCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: cyanNeon,
        foregroundColor: bgDeep,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: cyanNeon,
        suffixIconColor: textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: cyanNeon, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: borderSubtle,
      listTileTheme: const ListTileThemeData(
        iconColor: cyanNeon,
        textColor: textPrimary,
      ),
    );
  }
}
