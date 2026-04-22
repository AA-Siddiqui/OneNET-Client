import 'package:flutter/material.dart';
import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/services/vpn_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';

class VpnUsageMeterCard extends StatefulWidget {
  final String? authToken;
  final ConnectionStatus connectionStatus;

  const VpnUsageMeterCard({super.key, required this.authToken, required this.connectionStatus});

  @override
  State<VpnUsageMeterCard> createState() => _VpnUsageMeterCardState();
}

class _VpnUsageMeterCardState extends State<VpnUsageMeterCard> {
  VpnMeteredUsage? _usage;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshUsage();
  }

  @override
  void didUpdateWidget(covariant VpnUsageMeterCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final tokenChanged = oldWidget.authToken != widget.authToken;
    final disconnectedNow =
        oldWidget.connectionStatus != ConnectionStatus.disconnected &&
        widget.connectionStatus == ConnectionStatus.disconnected;

    if (tokenChanged || disconnectedNow) {
      _refreshUsage();
    }
  }

  Future<void> _refreshUsage() async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _usage = null;
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usage = await VpnService.fetchMeteredUsage(token: token);
      if (!mounted) return;
      setState(() {
        _usage = usage;
      });
    } on VpnException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load VPN usage.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatGiB(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MONTHLY VPN DATA', style: AppTextStyles.mono.copyWith(color: AppColors.accentBright)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  onPressed: _refreshUsage,
                  tooltip: 'Refresh usage',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textDim),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (usage == null && _error == null)
            Text('Sign in to view monthly usage.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDim))
          else if (usage == null && _error != null)
            Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))
          else if (usage != null) ...[
            Text(
              '${_formatGiB(usage.usedGiB)} GB / ${_formatGiB(usage.allowedGiB)} GB',
              style: AppTextStyles.heading3.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: usage.usageRatio,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  usage.usageRatio >= 0.95 ? AppColors.error : AppColors.accentBright,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Remaining ${_formatGiB(usage.remainingGiB)} GB',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDim),
                ),
                const Spacer(),
                Text(
                  usage.isPaidUser ? 'PAID PLAN' : 'FREE PLAN',
                  style: AppTextStyles.monoSmall.copyWith(color: usage.isPaidUser ? AppColors.success : AppColors.gold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
