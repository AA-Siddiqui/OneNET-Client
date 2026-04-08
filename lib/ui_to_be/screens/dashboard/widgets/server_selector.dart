import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/glow_container.dart';

class ServerSelector extends StatelessWidget {
  const ServerSelector({super.key});

  void _showLocationPicker(BuildContext context, VpnProvider vpn) {
    final selectedServer = vpn.server;
    final canSwitch = vpn.status == ConnectionStatus.disconnected;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.72;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SELECT LOCATION',
                    style: AppTextStyles.mono.copyWith(letterSpacing: 2, fontSize: 12, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 16),
                  if (!canSwitch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Disconnect VPN to switch location.',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
                      ),
                    ),
                  if (vpn.nodesErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        vpn.nodesErrorMessage!,
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  Flexible(
                    child: vpn.isLoadingServers
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.accentBright),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              ...vpn.servers.map(
                                (server) => _buildServerTile(
                                  context: context,
                                  vpn: vpn,
                                  server: server,
                                  isSelected: server.id == selectedServer.id,
                                  canSwitch: canSwitch,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCustomConnectionTile(context),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerTile({
    required BuildContext context,
    required VpnProvider vpn,
    required ServerModel server,
    required bool isSelected,
    required bool canSwitch,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: canSwitch
            ? () {
                vpn.selectServer(server.id);
                Navigator.of(context).pop();
              }
            : null,
        child: Opacity(
          opacity: canSwitch ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentGlow : AppColors.surface,
              border: Border.all(color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _badgeText(server),
                      style: const TextStyle(color: AppColors.accentBright, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.name.toUpperCase(), style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                      Text(
                        '${server.region} · ${server.nodeId}',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isSelected ? AppColors.accentBright : AppColors.textDim,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomConnectionTile(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.of(context).pop();
          CurrentAppBridge.showAddProfile();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.plus, color: AppColors.accentBright, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADD CUSTOM CONNECTION', style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                    Text(
                      'Import or add your own Hiddify profile',
                      style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textDim, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        final server = vpn.server;

        return GestureDetector(
          onTap: () => _showLocationPicker(context, vpn),
          child: GlowContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.accentGlow, borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: Text(
                      _badgeText(server),
                      style: const TextStyle(color: AppColors.accentBright, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.name.toUpperCase(), style: AppTextStyles.heading3),
                      Text(
                        '${server.region} · ${server.nodeId}',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronDown, color: AppColors.textDim, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  String _badgeText(ServerModel server) {
    final token = server.region.trim();
    if (token.length >= 2) {
      return token.substring(0, 2).toUpperCase();
    }

    final name = server.name.trim();
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }

    return 'VP';
  }
}
