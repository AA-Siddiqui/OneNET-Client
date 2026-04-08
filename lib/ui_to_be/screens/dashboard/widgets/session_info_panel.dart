import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../enums/connection_status.dart';
import '../../../providers/vpn_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/glow_container.dart';
import '../../../widgets/common/section_header.dart';

class SessionInfoPanel extends StatelessWidget {
  const SessionInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        if (vpn.status != ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(label: 'SESSION'),
            GlowContainer(
              borderColor: AppColors.accent,
              showGlow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('// DURATION', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.duration(vpn.connectedDuration),
                          style: AppTextStyles.monoBig.copyWith(fontSize: 28),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: AppColors.border),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('// IP ADDRESS', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
                        const SizedBox(height: 6),
                        Text(
                          vpn.assignedIp ?? '---',
                          style: AppTextStyles.mono.copyWith(color: AppColors.accentBright, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
