import 'package:flutter/material.dart';

sealed class AppColors {
  // Backgrounds
  static const Color black = Color(0xFF050810);
  static const Color navy = Color(0xFF080E1E);
  static const Color blueDark = Color(0xFF0A1628);

  // Accents
  static const Color accent = Color(0xFF1A8FFF);
  static const Color accentBright = Color(0xFF00C2FF);
  static const Color accentGlow = Color(0x401A8FFF);

  // Grid / Borders
  static const Color gridLine = Color(0x141A8FFF);
  static const Color border = Color(0x331A8FFF);
  static const Color borderBright = Color(0x8000C2FF);

  // Text
  static const Color text = Color(0xFFC8D8F0);
  static const Color textDim = Color(0xFF6A85A8);
  static const Color textBright = Color(0xFFE8F2FF);

  // Gold
  static const Color gold = Color(0xFFF0C040);
  static const Color goldDim = Color(0x26F0C040);

  // Functional
  static const Color error = Color(0xFFFF5050);
  static const Color success = Color(0xFF40E080);
  static const Color surface = Color(0xFF0D1B2A);
  static const Color surfaceLight = Color(0xFF112240);
}
