import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Apple-inspired green color scheme
  static const Color primary = Color(0xFF34C759); // Apple Green
  static const Color secondary = Color(0xFF30D158); // Light Green
  static const Color accent = Color(0xFF32D74B); // Bright Green
  static const Color success = Color(0xFF34C759); // Green
  static const Color warning = Color(0xFFFF9500); // Orange
  static const Color danger = Color(0xFFFF3B30); // Red
  static const Color dark = Color(0xFF1C1C1E); // Dark background
  static const Color light = Color(0xFFF2F2F7); // Light background
  static const Color grey = Color(0xFF8E8E93); // System Gray
  static const Color greyLight = Color(0xFFE5E5EA); // System Gray 5
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Additional Apple system colors
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // Sizes
  static const double baseSize = 8.0;
  static const double fontSize = 14.0;
  static const double radius = 12.0;
  static const double padding = 24.0;
  static const double margin = 20.0;

  // Font sizes
  static const double largeTitleSize = 40.0;
  static const double h1Size = 30.0;
  static const double h2Size = 22.0;
  static const double h3Size = 18.0;
  static const double h4Size = 16.0;
  static const double h5Size = 14.0;
  static const double body1Size = 30.0;
  static const double body2Size = 22.0;
  static const double body3Size = 16.0;
  static const double body4Size = 14.0;
  static const double body5Size = 12.0;
  static const double smallSize = 10.0;

  // Text styles
  static const TextStyle largeTitle =
      TextStyle(fontSize: largeTitleSize, fontWeight: FontWeight.bold);
  static const TextStyle h1 =
      TextStyle(fontSize: h1Size, fontWeight: FontWeight.bold);
  static const TextStyle h2 =
      TextStyle(fontSize: h2Size, fontWeight: FontWeight.bold);
  static const TextStyle h3 =
      TextStyle(fontSize: h3Size, fontWeight: FontWeight.w600);
  static const TextStyle h4 =
      TextStyle(fontSize: h4Size, fontWeight: FontWeight.w600);
  static const TextStyle h5 =
      TextStyle(fontSize: h5Size, fontWeight: FontWeight.w600);
  static const TextStyle body1 = TextStyle(fontSize: body1Size);
  static const TextStyle body2 = TextStyle(fontSize: body2Size);
  static const TextStyle body3 = TextStyle(fontSize: body3Size);
  static const TextStyle body4 = TextStyle(fontSize: body4Size);
  static const TextStyle body5 = TextStyle(fontSize: body5Size);
  static const TextStyle small = TextStyle(fontSize: smallSize);

  // Shadows
  static BoxShadow lightShadow = BoxShadow(
    color: black.withOpacity(0.1),
    offset: const Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  static BoxShadow mediumShadow = BoxShadow(
    color: black.withOpacity(0.15),
    offset: const Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  );

  static BoxShadow darkShadow = BoxShadow(
    color: black.withOpacity(0.2),
    offset: const Offset(0, 6),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // Common decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [lightShadow],
  );

  static BoxDecoration outlineDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: greyLight),
  );

  // Theme data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: light,
    fontFamily: 'SF Pro Display', // Apple's system font
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleLarge: h4,
      titleMedium: h5,
      bodyLarge: body3,
      bodyMedium: body4,
      bodySmall: body5,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: black,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        shadowColor: primary.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primary,
      unselectedItemColor: systemGray,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: dark,
    fontFamily: 'SF Pro Display', // Apple's system font
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleLarge: h4,
      titleMedium: h5,
      bodyLarge: body3,
      bodyMedium: body4,
      bodySmall: body5,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2C2C2E),
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        shadowColor: primary.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2C2C2E),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2C2C2E),
      selectedItemColor: primary,
      unselectedItemColor: systemGray,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
