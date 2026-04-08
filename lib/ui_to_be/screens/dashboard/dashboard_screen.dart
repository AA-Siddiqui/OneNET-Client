import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/utils/formatters.dart';
import 'package:hiddify/ui_to_be/utils/vpn_trace.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/cloud_gaming_button.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/dashboard_header.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/one_mail_panel.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/server_selector.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/speed_indicator.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/widgets/vpn_toggle_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOneMailSelected = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<UserProvider, bool>((user) => user.user?.isAdmin ?? false);

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            Column(
              children: [
                DashboardHeader(
                  isOneMailSelected: _isOneMailSelected,
                  onTabChanged: (isOneMail) {
                    setState(() => _isOneMailSelected = isOneMail);
                  },
                ),
                Expanded(child: _isOneMailSelected ? OneMailPanel(isAdmin: isAdmin) : _buildOneNetPanel(context)),
              ],
            ),

            // Floating settings button
            if (!_isOneMailSelected)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child:
                    Center(
                          child: _FloatingSettingsButton(onTap: () => Navigator.of(context).pushNamed(Routes.settings)),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms)
                        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 500.ms),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneNetPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        children: [
          // Connection status text
          Consumer<VpnProvider>(
            builder: (context, vpn, _) {
              final isConnected = vpn.status == ConnectionStatus.connected;
              final isConnecting = vpn.status == ConnectionStatus.connecting;

              final Color statusColor = isConnected
                  ? AppColors.success
                  : isConnecting
                  ? AppColors.gold
                  : AppColors.textDim;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          boxShadow: isConnected ? [BoxShadow(color: statusColor, blurRadius: 6)] : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        vpn.status.label,
                        style: AppTextStyles.mono.copyWith(color: statusColor, letterSpacing: 2, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isConnected ? Formatters.duration(vpn.connectedDuration) : '00:00:00',
                    style: AppTextStyles.monoBig.copyWith(
                      fontSize: 28,
                      color: isConnected ? AppColors.accentBright : AppColors.textDim.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms);
            },
          ),
          const SizedBox(height: 28),

          // VPN Toggle — centerpiece
          Center(
            child: const VpnToggleButton()
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms, delay: 100.ms),
          ),
          const SizedBox(height: 28),

          // Speed indicators
          const SpeedIndicator().animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 20),

          // Error message
          Consumer<VpnProvider>(
            builder: (context, vpn, _) {
              if (vpn.errorMessage == null) {
                return const SizedBox.shrink();
              }

              final isPermissionPrompt = vpn.needsVpnPermission;
              final baseColor = isPermissionPrompt ? AppColors.gold : AppColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1),
                    border: Border.all(color: baseColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vpn.errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: baseColor)),
                      if (isPermissionPrompt) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Tap below to request VPN permission again.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDim),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            final token = context.read<AuthProvider>().token;
                            final traceId = VpnTraceLogger.newTraceId();

                            VpnTraceLogger.log(
                              traceId: traceId,
                              layer: 'client.ui.permission_retry',
                              step: 'button_pressed',
                              details: <String, Object?>{
                                'status_before_press': vpn.status.name,
                                'has_auth_token': token != null,
                                'selected_server': vpn.server.publicIp,
                              },
                            );

                            context.read<VpnProvider>().connect(authToken: token, traceId: traceId);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: Text(
                            'Grant VPN Permission',
                            style: AppTextStyles.mono.copyWith(color: AppColors.gold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Server selector
          const ServerSelector().animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 16),

          // Cloud Gaming button — only for Cloud Gaming plan
          Consumer<UserProvider>(
            builder: (context, user, _) {
              if (!user.isCloudGamingUser) {
                return const SizedBox.shrink();
              }

              return CloudGamingButton(
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.cloudGaming);
                },
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
            },
          ),
        ],
      ),
    );
  }
}

class _FloatingSettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingSettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: AppColors.black.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 4),
          ],
        ),
        child: const Icon(Icons.grid_view_rounded, color: AppColors.accentBright, size: 22),
      ),
    );
  }
}
