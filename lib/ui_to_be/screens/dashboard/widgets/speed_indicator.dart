import 'dart:async';
import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/services/network_speed_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/services/storage_service.dart';
import 'dart:math';

/// Maximum number of data-points visible in the graph (60 s window @ 1 Hz).
const _maxDataPoints = 60;

class SpeedIndicator extends StatefulWidget {
  const SpeedIndicator({super.key});

  @override
  State<SpeedIndicator> createState() => _SpeedIndicatorState();
}

class _SpeedIndicatorState extends State<SpeedIndicator> {
  final _service = NetworkSpeedService();
  StreamSubscription<NetworkSpeed>? _sub;

  double _download = 0;
  double _upload = 0;

  final _dlHistory = Queue<double>();
  final _ulHistory = Queue<double>();

  bool _wasConnected = false;

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final persistedDownloadSpeed = await StorageService.getTopDownloadSpeed() ?? 0;
    final persistedUploadSpeed = await StorageService.getTopDownloadSpeed() ?? 0;
    _service.start();
    _sub ??= _service.speedStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _download = max(persistedDownloadSpeed, max(_download, s.downloadMbps));
        _upload = max(persistedUploadSpeed, max(_upload, s.uploadMbps));
        _dlHistory.addLast(s.downloadMbps);
        _ulHistory.addLast(s.uploadMbps);
        if (_dlHistory.length > _maxDataPoints) _dlHistory.removeFirst();
        if (_ulHistory.length > _maxDataPoints) _ulHistory.removeFirst();
      });
    });
  }

  Future<void> _stop() async {
    _sub?.cancel();
    _sub = null;
    _service.stop();
    await StorageService.saveTopDownloadSpeed(0);
    await StorageService.saveTopUploadSpeed(0);
    setState(() {
      _download = 0;
      _upload = 0;
      _dlHistory.clear();
      _ulHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        final isConnected = vpn.status == ConnectionStatus.connected;

        if (isConnected && !_wasConnected) {
          _wasConnected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _start();
          });
        } else if (vpn.status == ConnectionStatus.disconnected && _wasConnected) {
          _wasConnected = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _stop();
          });
        }

        return Column(
          children: [
            // Speed cards
            Row(
              children: [
                Expanded(
                  child: _SpeedCard(
                    icon: LucideIcons.arrowDown,
                    label: 'DOWNLOAD',
                    speed: _download,
                    unit: 'Mbps',
                    isActive: isConnected,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SpeedCard(
                    icon: LucideIcons.arrowUp,
                    label: 'UPLOAD',
                    speed: _upload,
                    unit: 'Mbps',
                    isActive: isConnected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Graph
            _SpeedGraph(dlHistory: _dlHistory, ulHistory: _ulHistory, isActive: isConnected),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Speed card (download / upload number display)
// ---------------------------------------------------------------------------
class _SpeedCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double speed;
  final String unit;
  final bool isActive;

  const _SpeedCard({
    required this.icon,
    required this.label,
    required this.speed,
    required this.unit,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accentBright : AppColors.textDim;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        border: Border.all(color: isActive ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim, fontSize: 9, letterSpacing: 1.5),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isActive ? speed.toStringAsFixed(1) : '—',
                      style: AppTextStyles.mono.copyWith(color: color, fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 3),
                      Text(unit, style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim, fontSize: 9)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line chart showing recent download / upload speed history
// ---------------------------------------------------------------------------
class _SpeedGraph extends StatelessWidget {
  final Queue<double> dlHistory;
  final Queue<double> ulHistory;
  final bool isActive;

  const _SpeedGraph({required this.dlHistory, required this.ulHistory, required this.isActive});

  List<FlSpot> _toSpots(Queue<double> q) {
    final list = q.toList();
    return List.generate(list.length, (i) => FlSpot(i.toDouble(), list[i]));
  }

  double _maxY() {
    double m = 5; // Minimum Y axis ceiling
    for (final v in dlHistory) {
      if (v > m) m = v;
    }
    for (final v in ulHistory) {
      if (v > m) m = v;
    }
    return (m * 1.25).ceilToDouble(); // 25 % headroom
  }

  @override
  Widget build(BuildContext context) {
    final hasData = dlHistory.isNotEmpty || ulHistory.isNotEmpty;
    final maxY = _maxY();

    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        border: Border.all(color: isActive ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: hasData && isActive
          ? LineChart(
              LineChartData(
                minX: 0,
                maxX: (_maxDataPoints - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.gridLine, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxY / 2,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: AppTextStyles.monoSmall.copyWith(
                          color: AppColors.textDim.withValues(alpha: 0.5),
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  // Download line — cyan / accent
                  LineChartBarData(
                    spots: _toSpots(dlHistory),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    preventCurveOverShooting: true,
                    color: AppColors.accentBright,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accentBright.withValues(alpha: 0.2),
                          AppColors.accentBright.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Upload line — dimmer blue
                  LineChartBarData(
                    spots: _toSpots(ulHistory),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    preventCurveOverShooting: true,
                    color: AppColors.accent.withValues(alpha: 0.6),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.accent.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                isActive ? 'Collecting data…' : '// NETWORK ACTIVITY',
                style: AppTextStyles.monoSmall.copyWith(
                  color: AppColors.textDim.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
            ),
    );
  }
}
