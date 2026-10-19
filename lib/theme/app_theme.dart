import 'package:flutter/material.dart';
export 'mascot_theme.dart';

/// Design tokens and styling for Spentee matching the visual design reference.
class AppTheme {
  // Brand Background Colors (Deep navy / near black matching #001422)
  static const Color bgDark = Color(0xFF001422);
  static const Color bgSurface = Color(0xFF081424);
  static const Color bgCard = Color(0xFF0C1F36);
  static const Color bgCardLighter = Color(0xFF132B48);
  static const Color bgElevated = Color(0xFF173254);

  // Brand Accent Colors
  static const Color primaryMint = Color(0xFF00E676);
  static const Color primaryMintGlow = Color(0xFF33FF99);
  static const Color primaryMintDark = Color(0xFF00B359);
  static const Color accentPink = Color(0xFFFF3366);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color accentYellow = Color(0xFFFFD600);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF8E9DAE);
  static const Color textDim = Color(0xFF556980);

  // Border Colors
  static const Color borderColor = Color(0x3300E676);
  static const Color borderSubtle = Color(0x1FFFFFFF);

  // Gradients
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B359)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF0F2642), Color(0xFF091626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roastCardGradient = LinearGradient(
    colors: [Color(0xFF3E1E34), Color(0xFF1E132B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gameOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gamePurpleGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gameBlueGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gamePinkGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// ThemeData for MaterialApp
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryMint,
      canvasColor: bgSurface,
      cardColor: bgCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryMint,
        secondary: accentCyan,
        surface: bgSurface,
        onSurface: textWhite,
        error: accentPink,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMint,
          foregroundColor: bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }

  /// Light ThemeData for MaterialApp
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      primaryColor: const Color(0xFF00B359),
      canvasColor: const Color(0xFFE2E8F0),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00B359),
        secondary: Color(0xFF0284C7),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        error: accentPink,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      useMaterial3: true,
    );
  }
}
