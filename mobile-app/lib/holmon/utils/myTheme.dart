import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // Theme 1: Premium Ocean Blue (Light)
  static final lightTheme1 = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFF0F9FF),
      primary: const Color(0xFF0284C7),
      secondary: const Color(0xFFBAE6FD),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFF0284C7),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0284C7),
        selectedItemColor: Color(0xFF0284C7),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.shifting),
    scaffoldBackgroundColor: const Color(0xFFF0F9FF),
    cardColor: const Color(0xFFE0F2FE),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF0284C7)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Theme 2: Premium Soft Lavender (Light)
  static final darkTheme2 = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFFAF5FF),
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFFE9D5FF),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFF7C3AED),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF7C3AED),
      selectedItemColor: Color(0xFF7C3AED),
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.shifting,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF5FF),
    cardColor: const Color(0xFFF3E8FF),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF7C3AED)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Premium Theme 3: Fresh Organic Green (Light)
  static final organicGreenTheme = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFF4F8F5),
      primary: const Color(0xFF006E2F),
      secondary: const Color(0xFFA7F3D0),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFF006E2F),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF006E2F),
        selectedItemColor: Color(0xFF006E2F),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.shifting),
    scaffoldBackgroundColor: const Color(0xFFF4F8F5),
    cardColor: const Color(0xFFE6F4EA),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF006E2F)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Premium Theme 4: Sunset Orange (Light)
  static final sunsetOrangeTheme = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFFFF7ED),
      primary: const Color(0xFFE65100),
      secondary: const Color(0xFFFED7AA),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFFE65100),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFE65100),
        selectedItemColor: Color(0xFFE65100),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.shifting),
    scaffoldBackgroundColor: const Color(0xFFFFF7ED),
    cardColor: const Color(0xFFFFEDD5),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFE65100)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Premium Theme 5: Champagne Gold (Light)
  static final premiumGoldTheme = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFFEFDFB),
      primary: const Color(0xFFB45309),
      secondary: const Color(0xFFFDE68A),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFFB45309),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFB45309),
      selectedItemColor: Color(0xFFB45309),
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.shifting,
    ),
    scaffoldBackgroundColor: const Color(0xFFFEFDFB),
    cardColor: const Color(0xFFFEF3C7),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFB45309)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Premium Theme 6: Royal Purple (Light)
  static final royalPurpleTheme = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFFAF5FF),
      primary: const Color(0xFF6D28D9),
      secondary: const Color(0xFFDDD6FE),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFF6D28D9),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF6D28D9),
        selectedItemColor: Color(0xFF6D28D9),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.shifting),
    scaffoldBackgroundColor: const Color(0xFFFAF5FF),
    cardColor: const Color(0xFFEDE9FE),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF6D28D9)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  // Premium Theme 7: Midnight Frost (Light)
  static final midnightBlueTheme = ThemeData(
    colorScheme: ColorScheme.light(
      background: const Color(0xFFF8FAFC),
      primary: const Color(0xFF1E3A8A),
      secondary: const Color(0xFFBFDBFE),
      surface: Colors.white,
    ),
    primaryColor: const Color(0xFF1E3A8A),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E3A8A),
      selectedItemColor: Color(0xFF1E3A8A),
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.shifting,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardColor: const Color(0xFFE2E8F0),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(color: Color(0xFF1E293B)),
    ),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF1E3A8A)),
      ),
      constraints: const BoxConstraints.expand(height: 48),
    ),
  );

  /// Map helper to find theme by unique name key
  static ThemeData getThemeByKey(String key) {
    switch (key) {
      case 'light_blue':
        return lightTheme1;
      case 'dark_blue':
        return darkTheme2;
      case 'organic_green':
        return organicGreenTheme;
      case 'sunset_orange':
        return sunsetOrangeTheme;
      case 'premium_gold':
        return premiumGoldTheme;
      case 'royal_purple':
        return royalPurpleTheme;
      case 'midnight_blue':
        return midnightBlueTheme;
      default:
        return organicGreenTheme; // Fresh organic green is default premium theme
    }
  }
}
