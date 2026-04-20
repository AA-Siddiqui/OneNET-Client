import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/enums/game_session_status.dart';
import 'package:hiddify/ui_to_be/providers/game_session_provider.dart';
import 'package:hiddify/ui_to_be/services/url_launcher_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hiddify/ui_to_be/widgets/common/section_header.dart';
import 'package:hiddify/ui_to_be/screens/cloud_gaming/widgets/game_launch_card.dart';
import 'package:hiddify/ui_to_be/screens/cloud_gaming/widgets/session_status_display.dart';
import 'package:hiddify/ui_to_be/screens/cloud_gaming/widgets/steam_login_prompt.dart';

class CloudGamingScreen extends StatefulWidget {
  const CloudGamingScreen({super.key});

  @override
  State<CloudGamingScreen> createState() => _CloudGamingScreenState();
}

class _CloudGamingScreenState extends State<CloudGamingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameSessionProvider>().checkFirstTimeStatus();
  }

  void _showSteamLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SteamLoginPrompt(
        onContinue: () {
          Navigator.of(context).pop();
          final provider = context.read<GameSessionProvider>();
          provider.markFirstTimeComplete();
          provider.launchSession();
        },
        onLearnMore: () {
          UrlLauncherService.openSupport();
        },
      ),
    );
  }

  void _handleLaunch() {
    final provider = context.read<GameSessionProvider>();
    if (provider.isFirstTimeSetup) {
      _showSteamLoginPrompt();
    } else {
      provider.launchSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 24, 0),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.95),
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textBright, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text('eCG GAMING', style: AppTextStyles.heading3.copyWith(letterSpacing: 2)),
                    const Spacer(),
                    Consumer<GameSessionProvider>(
                      builder: (context, session, _) {
                        final Color statusColor = switch (session.status) {
                          GameSessionStatus.active => AppColors.success,
                          GameSessionStatus.launching => AppColors.gold,
                          GameSessionStatus.error => AppColors.error,
                          GameSessionStatus.idle => AppColors.textDim,
                        };
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            session.status.label,
                            style: AppTextStyles.monoSmall.copyWith(color: statusColor),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Consumer<GameSessionProvider>(
                  builder: (context, session, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(label: 'GAME SESSION'),

                        if (session.status == GameSessionStatus.idle)
                          GameLaunchCard(onLaunch: _handleLaunch).animate().fadeIn(duration: 400.ms),

                        if (session.status == GameSessionStatus.launching)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 48),
                                const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBright),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'LAUNCHING SESSION...',
                                  style: AppTextStyles.heading3.copyWith(color: AppColors.accent, letterSpacing: 2),
                                ),
                                const SizedBox(height: 8),
                                Text('Connecting to Malaysia gaming server', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),

                        if (session.status == GameSessionStatus.active)
                          const SessionStatusDisplay().animate().fadeIn(duration: 400.ms),

                        if (session.status == GameSessionStatus.error) ...[
                          const SizedBox(height: 32),
                          Center(
                            child: Column(
                              children: [
                                const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
                                const SizedBox(height: 16),
                                Text('SESSION ERROR', style: AppTextStyles.heading3.copyWith(color: AppColors.error)),
                                const SizedBox(height: 8),
                                Text(
                                  session.errorMessage ?? 'Failed to launch session.',
                                  style: AppTextStyles.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton(
                                  onPressed: () => session.endSession(),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border),
                                    foregroundColor: AppColors.accentBright,
                                  ),
                                  child: Text('TRY AGAIN', style: AppTextStyles.mono),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Performance specs note
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 3)),
                            color: AppColors.goldDim.withValues(alpha: 0.3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PERFORMANCE TARGET',
                                style: AppTextStyles.monoSmall.copyWith(color: AppColors.gold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '30fps / 1080p / <80ms latency · H.264 · 10-20 Mbps adaptive\nOptimized for RPG, strategy, and story-driven titles.',
                                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
