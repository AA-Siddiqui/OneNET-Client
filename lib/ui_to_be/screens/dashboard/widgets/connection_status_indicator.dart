import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../enums/connection_status.dart';
import '../../../providers/vpn_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/glow_container.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        final status = vpn.status;
        final Color statusColor = switch (status) {
          ConnectionStatus.connected => AppColors.success,
          ConnectionStatus.connecting => AppColors.gold,
          ConnectionStatus.disconnected => AppColors.textDim,
        };

        return GlowContainer(
          borderColor: status == ConnectionStatus.connected ? AppColors.accent : AppColors.border,
          showGlow: status == ConnectionStatus.connected,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: status == ConnectionStatus.connected
                      ? [BoxShadow(color: statusColor, blurRadius: 6)]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(status.label, style: AppTextStyles.mono.copyWith(color: statusColor, letterSpacing: 2)),
              const Spacer(),
              Text('WIREGUARD', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
            ],
          ),
        );
      },
    );
  }
}
