import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';

import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/services/url_launcher_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hiddify/ui_to_be/widgets/common/section_header.dart';
import 'package:hiddify/ui_to_be/screens/settings/widgets/account_info_card.dart';
import 'package:hiddify/ui_to_be/screens/settings/widgets/app_version_display.dart';
import 'package:hiddify/ui_to_be/screens/settings/widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.95),
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentGlow.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, color: AppColors.accentBright, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('SETTINGS', style: AppTextStyles.heading3.copyWith(letterSpacing: 2)),
                    const Spacer(),
                    Text('// ACCOUNT', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(label: 'ACCOUNT'),
                    const AccountInfoCard().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 28),
                    const SectionHeader(label: 'MANAGE'),
                    SettingsTile(
                      icon: LucideIcons.layoutDashboard,
                      title: 'Open Hiddify Advanced',
                      subtitle: 'Access existing screens and flows',
                      onTap: () {
                        final rootContext = rootNavKey.currentContext;
                        if (rootContext != null) {
                          GoRouter.of(rootContext).go('/home');
                        }
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                    SettingsTile(
                      icon: LucideIcons.globe,
                      title: 'Manage Account',
                      subtitle: 'Open portal in browser',
                      onTap: () => UrlLauncherService.openAccount(),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    SettingsTile(
                      icon: LucideIcons.helpCircle,
                      title: 'Support / Help',
                      subtitle: 'Contact support team',
                      onTap: () => UrlLauncherService.openSupport(),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                    SettingsTile(
                      icon: LucideIcons.download,
                      title: 'Downloads',
                      subtitle: 'Get latest app version',
                      onTap: () => UrlLauncherService.openDownloads(),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 28),
                    const SectionHeader(label: 'SESSION'),
                    SettingsTile(
                      icon: LucideIcons.logOut,
                      title: 'Logout',
                      subtitle: 'Sign out of this device',
                      isDestructive: true,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            title: Text('LOGOUT', style: AppTextStyles.heading3),
                            content: Text('Are you sure you want to sign out?', style: AppTextStyles.bodyMedium),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('CANCEL', style: AppTextStyles.mono.copyWith(color: AppColors.textDim)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('LOGOUT', style: AppTextStyles.mono.copyWith(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          context.read<UserProvider>().clear();
                          Navigator.of(context).pushReplacementNamed(Routes.login);
                        }
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                    const SizedBox(height: 48),
                    const AppVersionDisplay().animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
