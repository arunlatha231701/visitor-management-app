
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF172B4D);
  static const Color navyLight = Color(0xFF263F63);
  static const Color teal = Color(0xFF087F8C);

  // Light theme.
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF192B45);
  static const Color textSecondary = Color(0xFF65758B);
  static const Color border = Color(0xFFE1E7EF);

  // Dark theme.
  static const Color darkBackground = Color(0xFF0D1522);
  static const Color darkSurface = Color(0xFF172334);
  static const Color darkSurfaceElevated = Color(0xFF202F43);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFADBBCD);
  static const Color darkBorder = Color(0xFF344459);

  // Semantic colors.
  static const Color success = Color(0xFF18794E);
  static const Color warning = Color(0xFF9A6700);
  static const Color danger = Color(0xFFB42318);

  // Dark-mode variants with stronger contrast on dark surfaces.
  static const Color darkSuccess = Color(0xFF75D6A5);
  static const Color darkWarning = Color(0xFFFFD080);
  static const Color darkDanger = Color(0xFFFF8F86);
}
