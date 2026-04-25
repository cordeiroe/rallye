import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: background,
  colorScheme: const ColorScheme.dark(
    surface: surface,
    primary: accent,
    error: error,
  ),
  textTheme: TextTheme(
    displayLarge: spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700),
    displayMedium: spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: outfit(fontSize: 16),
    bodyMedium: outfit(fontSize: 14),
    bodySmall: outfit(fontSize: 12, color: textSecondary),
    labelLarge: outfit(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: outfit(fontSize: 11, color: textSecondary),
  ),
);
