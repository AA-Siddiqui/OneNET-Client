import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/game_session_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/glow_container.dart';

class SessionStatusDisplay extends StatelessWidget {
  const SessionStatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSessionProvider>(
      builder: (context, session, _) {
        return GlowContainer(
          borderColor: AppColors.success.withValues(alpha: 0.3),
          showGlow: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                      boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SESSION ACTIVE',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.success, letterSpacing: 2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.clock, color: AppColors.textDim, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${Formatters.duration(session.sessionDuration)}',
                    style: AppTextStyles.mono.copyWith(color: AppColors.accentBright),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Server: Malaysia · KL-NODE-01', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
              const SizedBox(height: 8),
              Text(
                '1080p · 30fps · Sunshine/Moonlight',
                style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => session.endSession(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderBright),
                    foregroundColor: AppColors.accentBright,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'END SESSION',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.accentBright, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
