import 'package:flutter/material.dart';

class AppTheme {
  // Material Design 3 Light ColorScheme (from user specification)
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF336B23),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB3F39B),
    onPrimaryContainer: Color(0xFF032100),
    secondary: Color(0xFF6250A9),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE6DEFF),
    onSecondaryContainer: Color(0xFF1D0061),
    tertiary: Color(0xFF7D5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD9E3),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFAFAF3),
    onSurface: Color(0xFF1A1C18),
    outline: Color(0xFF73796E),
    outlineVariant: Color(0xFFC3C8BC),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F4ED),
    surfaceContainer: Color(0xFFEEEEE8),
    surfaceContainerHigh: Color(0xFFE8E9E2),
    surfaceContainerHighest: Color(0xFFE3E3DC),
  );

  // Material Design 3 Dark ColorScheme (aligned with light palette)
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF98D781),
    onPrimary: Color(0xFF063900),
    primaryContainer: Color(0xFF1B520D),
    onPrimaryContainer: Color(0xFFB3F39B),
    secondary: Color(0xFFCBBFFF),
    onSecondary: Color(0xFF331E78),
    secondaryContainer: Color(0xFF4A3890),
    onSecondaryContainer: Color(0xFFE6DEFF),
    tertiary: Color(0xFFEEB8C8),
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B49),
    onTertiaryContainer: Color(0xFFFFD9E3),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121410),
    onSurface: Color(0xFFE3E3DC),
    outline: Color(0xFF8D9387),
    outlineVariant: Color(0xFF43483F),
    surfaceContainerLowest: Color(0xFF0D0F0B),
    surfaceContainerLow: Color(0xFF1A1C18),
    surfaceContainer: Color(0xFF1E201C),
    surfaceContainerHigh: Color(0xFF292B26),
    surfaceContainerHighest: Color(0xFF333630),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: lightColorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lightColorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightColorScheme.surfaceContainer,
      indicatorColor: lightColorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: lightColorScheme.surfaceContainer,
      indicatorColor: lightColorScheme.primaryContainer,
      selectedLabelTextStyle: TextStyle(
        color: lightColorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: darkColorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkColorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkColorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkColorScheme.surfaceContainer,
      indicatorColor: darkColorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkColorScheme.surfaceContainer,
      indicatorColor: darkColorScheme.primaryContainer,
      selectedLabelTextStyle: TextStyle(
        color: darkColorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
