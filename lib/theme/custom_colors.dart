// lib/theme/custom_colors.dart
import 'package:flutter/material.dart';

class CustomColors {
  // === Core Palette ===
  static const Color deepBlue = Color(0xFF0D3B66); // Deep navy blue
  static const Color mutedBlue = Color(0xFF5C80BC); // Muted medium blue, used for text field text and borders
  static const Color softBlue = Color(0xFFA7C7E7);  // Soft pastel blue
  static const Color lightSky = Color(0xFFD6EFFF);  // Light sky blue
  static const Color background = Color(0xFFF5FAFF); // Very light blue-tinted background
  static const Color surface = Colors.white; // Changed to white for text fields
  static const Color onSurface = mutedBlue; // Text on the surface, e.g., text field input

  // === Text Colors ===
  static const Color textPrimary = deepBlue;
  static const Color textSecondary = background;

  // === UI Component Colors ===
  static const Color cardColor = lightSky;
  static const Color containerColor = softBlue;
  static const Color buttonHover = mutedBlue;

  // === Error & Misc ===
  static const Color error = Colors.redAccent;
  static const Color onError = background;

  // === Optional Border/Shadow ===
  static const Color borderColor = Color(0xFFB0C4DE); // Light steel blue
  static const Color shadowColor = Color(0x330D3B66); // 20% opacity deepBlue
}

ColorScheme customLightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: CustomColors.deepBlue,
  onPrimary: CustomColors.background,
  secondary: CustomColors.mutedBlue,
  onSecondary: CustomColors.background,
  error: CustomColors.error,
  onError: CustomColors.onError,
  background: CustomColors.background,
  onBackground: CustomColors.textPrimary,
  surface: CustomColors.surface,
  onSurface: CustomColors.onSurface,
);

ColorScheme customDarkColorScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: CustomColors.lightSky,
  onPrimary: CustomColors.background,
  secondary: CustomColors.softBlue,
  onSecondary: CustomColors.background,
  error: CustomColors.error,
  onError: CustomColors.onError,
  background: CustomColors.mutedBlue,
  onBackground: CustomColors.background,
  surface: CustomColors.softBlue,
  onSurface: CustomColors.background,
);