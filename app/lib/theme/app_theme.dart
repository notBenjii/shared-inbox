import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceVariant = Color(0xFF1A1A1A);
  static const border = Color(0xFF262626);
  static const primary = Color(0xFF2DD4A7);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF8A8A8A);
  static const error = Color(0xFFEF4444);

  static const List<Color> _devicePalette = [
    Color(0xFF2DD4A7), // teal
    Color(0xFFA78BFA), // purple
    Color(0xFF38BDF8), // cyan
    Color(0xFFFBBF24), // amber
    Color(0xFFF472B6), // pink
    Color(0xFF818CF8), // indigo
    Color(0xFF4ADE80), // green
    Color(0xFFFB923C), // orange
    Color(0xFF60A5FA), // blue
    Color(0xFFE879F9), // fuchsia
    Color(0xFFFACC15), // yellow
    Color(0xFF34D399), // emerald
  ];

  /// Derives a consistent color for any device name by hashing it,
  /// so custom/renamed devices still get a stable, distinct color
  /// without needing a hardcoded name-to-color map.
  static Color forDevice(String deviceName) {
    if (deviceName.isEmpty) return textSecondary;
    final hash = deviceName.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _devicePalette[(hash * 13) % _devicePalette.length];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
