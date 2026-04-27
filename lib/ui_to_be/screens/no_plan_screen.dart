import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/services/url_launcher_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/accent_button.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hiddify/ui_to_be/widgets/common/glow_container.dart';

class NoPlanScreen extends StatelessWidget {
  const NoPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),

                      // Logo
                      Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentGlow.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset('assets/ui-to-be/new_assets/images/logo.png', fit: BoxFit.contain),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOut),

                      const SizedBox(height: 28),

                      Text(
                        'NO ACTIVE PLAN',
                        style: AppTextStyles.heading2.copyWith(letterSpacing: 3),
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                      const SizedBox(height: 12),

                      Text(
                        'Your account does not have an active subscription. '
                        'Start a trial or subscribe to a paid plan on the eCG portal to continue.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDim, height: 1.6),
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 36),

                      // Trial cards
                      GlowContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('// TRIAL PLANS', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
                            const SizedBox(height: 16),
                            const _PlanRow(
                              name: '7-DAY TRIAL',
                              price: 'FREE',
                              description: 'No card required · one-time trial',
                              icon: LucideIcons.clock3,
                              accentColor: AppColors.gold,
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                            const _PlanRow(
                              name: '1-MONTH TRIAL',
                              price: 'HK\$0 now',
                              description: 'Card required · auto-reminder before trial end',
                              icon: LucideIcons.creditCard,
                              accentColor: AppColors.gold,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 260.ms),

                      const SizedBox(height: 16),

                      // Plan cards
                      GlowContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '// AVAILABLE PLANS',
                              style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
                            ),
                            const SizedBox(height: 16),
                            const _PlanRow(
                              name: 'VPS BASIC',
                              price: 'HK\$78/mo',
                              description: 'Personal tunnel',
                              icon: LucideIcons.shield,
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                            const _PlanRow(
                              name: 'CLOUD GAMING',
                              price: 'HK\$148/mo',
                              description: 'Basic + Cloud game streaming',
                              icon: LucideIcons.gamepad2,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 320.ms),

                      const SizedBox(height: 32),

                      AccentButton(
                        label: 'START TRIAL ON WEBSITE',
                        onPressed: () => UrlLauncherService.openPlans(),
                      ).animate().fadeIn(duration: 500.ms, delay: 380.ms),

                      const SizedBox(height: 12),

                      // Upgrade button
                      AccentButton(
                        label: 'UPGRADE ON WEBSITE',
                        onPressed: () => UrlLauncherService.openPlans(),
                      ).animate().fadeIn(duration: 500.ms, delay: 420.ms),

                      const SizedBox(height: 16),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            await context.read<AuthProvider>().logout();
                            if (!context.mounted) return;
                            context.read<UserProvider>().clear();
                            Navigator.of(context).pushReplacementNamed(Routes.login);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: Text(
                            'LOGOUT',
                            style: AppTextStyles.heading3.copyWith(color: AppColors.textDim, letterSpacing: 2),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 470.ms),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final IconData icon;
  final Color? accentColor;

  const _PlanRow({
    required this.name,
    required this.price,
    required this.description,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor ?? AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.mono.copyWith(color: AppColors.textBright, fontSize: 12)),
              Text(description, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
        Text(price, style: AppTextStyles.mono.copyWith(color: accentColor ?? AppColors.accentBright, fontSize: 12)),
      ],
    );
  }
}
