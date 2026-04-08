import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/accent_button.dart';

class SteamLoginPrompt extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onLearnMore;

  const SteamLoginPrompt({super.key, required this.onContinue, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: const Icon(LucideIcons.logIn, color: AppColors.gold, size: 28),
          ),
          const SizedBox(height: 20),
          Text('STEAM LOGIN REQUIRED', style: AppTextStyles.heading3.copyWith(color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            'This is your first cloud gaming session. You will be prompted to log in to Steam with your managed seat credentials inside the streaming session.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.text, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This is a one-time setup — subsequent sessions will auto-login.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AccentButton(label: 'CONTINUE', onPressed: onContinue),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onLearnMore,
            child: Text('LEARN MORE', style: AppTextStyles.mono.copyWith(color: AppColors.accentBright, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
