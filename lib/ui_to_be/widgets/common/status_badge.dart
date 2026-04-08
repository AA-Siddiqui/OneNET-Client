import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;

  const StatusBadge({super.key, required this.label, this.color = AppColors.accentBright, this.backgroundColor});

  factory StatusBadge.active() => const StatusBadge(label: 'ACTIVE', color: AppColors.success);

  factory StatusBadge.trialing() => const StatusBadge(label: 'TRIALING', color: AppColors.accentBright);

  factory StatusBadge.expired() => const StatusBadge(label: 'EXPIRED', color: AppColors.error);

  factory StatusBadge.pending() => const StatusBadge(label: 'PENDING', color: AppColors.gold);

  factory StatusBadge.plan(String planLabel) => StatusBadge(label: planLabel, color: AppColors.accentBright);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: AppTextStyles.monoSmall.copyWith(color: color)),
    );
  }
}
