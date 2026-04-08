import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

sealed class AppTextStyles {
  // Headings — Rajdhani
  static TextStyle heading1 = GoogleFonts.rajdhani(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textBright,
    letterSpacing: 2,
  );

  static TextStyle heading2 = GoogleFonts.rajdhani(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textBright,
    letterSpacing: 1.5,
  );

  static TextStyle heading3 = GoogleFonts.rajdhani(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textBright,
    letterSpacing: 1,
  );

  static TextStyle headingAccent = GoogleFonts.rajdhani(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.accentBright,
    letterSpacing: 3,
  );

  // Body — Inter
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.7,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.7,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: AppColors.textDim,
    height: 1.6,
  );

  // Mono — Share Tech Mono
  static TextStyle mono = GoogleFonts.shareTechMono(fontSize: 12, color: AppColors.accent, letterSpacing: 1);

  static TextStyle monoSmall = GoogleFonts.shareTechMono(fontSize: 10, color: AppColors.accentBright, letterSpacing: 2);

  static TextStyle monoBig = GoogleFonts.shareTechMono(fontSize: 42, color: AppColors.accentBright);

  static TextStyle monoLabel = GoogleFonts.shareTechMono(fontSize: 11, color: AppColors.textDim, letterSpacing: 2);
}
