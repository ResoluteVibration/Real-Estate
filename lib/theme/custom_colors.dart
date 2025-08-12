// lib/theme/custom_colors.dart
import 'package:flutter/material.dart';

class CustomColors {
  // === Core Palette ===
  static const Color darkGreen = Color(0xFF043F34); // Deep green
  static const Color mutedGreen = Color(0xFF71967D); // Slightly faded green
  static const Color softTeal = Color(0xFFAFCAB8);   // Pastel teal
  static const Color lightMint = Color(0xFFB6E5D2);  // Bright mint
  static const Color background = Color(0xFFF8F8F3); // Very light cream
  static const Color surface = softTeal;
  static const Color onSurface = darkGreen;

  // === Text Colors ===
  static const Color textPrimary = darkGreen;
  static const Color textSecondary = background;

  // === UI Component Colors ===
  static const Color cardColor = lightMint;
  static const Color containerColor = softTeal;
  static const Color buttonHover = mutedGreen;

  // === Error & Misc ===
  static const Color error = Colors.redAccent;
  static const Color onError = background;

  // === Optional Border/Shadow ===
  static const Color borderColor = Color(0xFFCBD5C2);
  static const Color shadowColor = Color(0x33043F34); // 20% opacity darkGreen
}

ColorScheme customLightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: CustomColors.darkGreen,
  onPrimary: CustomColors.background,
  secondary: CustomColors.mutedGreen,
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
  primary: CustomColors.lightMint,
  onPrimary: CustomColors.background,
  secondary: CustomColors.softTeal,
  onSecondary: CustomColors.background,
  error: CustomColors.error,
  onError: CustomColors.onError,
  background: CustomColors.mutedGreen,
  onBackground: CustomColors.background,
  surface: CustomColors.softTeal,
  onSurface: CustomColors.background,
);
