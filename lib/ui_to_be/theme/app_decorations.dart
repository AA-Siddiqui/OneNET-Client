import 'package:flutter/material.dart';
import 'app_colors.dart';

sealed class AppDecorations {
  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.7),
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(4),
  );

  static BoxDecoration cardElevated = BoxDecoration(
    color: AppColors.surfaceLight,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(4),
    boxShadow: const [BoxShadow(color: AppColors.accentGlow, blurRadius: 8)],
  );

  static BoxDecoration glowCard = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.9),
    border: Border.all(color: AppColors.accent),
    borderRadius: BorderRadius.circular(4),
    boxShadow: const [BoxShadow(color: AppColors.accentGlow, blurRadius: 16)],
  );

  static BoxDecoration goldCard = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.9),
    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
    borderRadius: BorderRadius.circular(4),
    boxShadow: [BoxShadow(color: AppColors.goldDim, blurRadius: 12)],
  );

  static BoxDecoration glowButton = BoxDecoration(
    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentBright]),
    borderRadius: BorderRadius.circular(50),
    boxShadow: const [BoxShadow(color: AppColors.accentGlow, blurRadius: 24, spreadRadius: 4)],
  );
}
