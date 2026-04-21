import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/glow_container.dart';

class CloudGamingButton extends StatelessWidget {
  final VoidCallback onTap;

  const CloudGamingButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlowContainer(
        borderColor: AppColors.gold.withValues(alpha: 0.3),
        showGlow: true,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.goldDim, borderRadius: BorderRadius.circular(4)),
              child: const Icon(LucideIcons.gamepad2, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('eCG GAMING', style: AppTextStyles.heading3.copyWith(color: AppColors.gold)),
                  Text(
                    'Launch game session · Moonlight / Sunshine',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}
