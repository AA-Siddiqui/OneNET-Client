import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/accent_button.dart';
import '../../../widgets/common/glow_container.dart';

class GameLaunchCard extends StatelessWidget {
  final VoidCallback onLaunch;
  final bool isLoading;

  const GameLaunchCard({super.key, required this.onLaunch, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      borderColor: AppColors.accent,
      showGlow: true,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGlow,
              border: Border.all(color: AppColors.accentBright.withValues(alpha: 0.3)),
            ),
            child: const Icon(LucideIcons.play, size: 36, color: AppColors.accentBright),
          ),
          const SizedBox(height: 24),
          Text('START SESSION', style: AppTextStyles.heading2.copyWith(letterSpacing: 3)),
          const SizedBox(height: 8),
          Text(
            'Connect to Malaysia gaming server\nvia Moonlight / Sunshine',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('// STREAM · 1080P · 30FPS · <80MS', style: AppTextStyles.monoSmall.copyWith(color: AppColors.gold)),
          const SizedBox(height: 28),
          AccentButton(label: 'LAUNCH', onPressed: isLoading ? null : onLaunch, isLoading: isLoading),
        ],
      ),
    );
  }
}
