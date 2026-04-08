import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../enums/connection_status.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vpn_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/vpn_trace.dart';

class VpnToggleButton extends StatefulWidget {
  const VpnToggleButton({super.key});

  @override
  State<VpnToggleButton> createState() => _VpnToggleButtonState();
}

class _VpnToggleButtonState extends State<VpnToggleButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VpnProvider, AuthProvider>(
      builder: (context, vpn, auth, _) {
        final isConnected = vpn.status == ConnectionStatus.connected;
        final isConnecting = vpn.status == ConnectionStatus.connecting;

        final Color primaryColor = isConnected
            ? AppColors.accentBright
            : isConnecting
            ? AppColors.accent
            : AppColors.textDim;

        return Column(
          children: [
            GestureDetector(
              onTap: isConnecting
                  ? null
                  : () {
                      final traceId = VpnTraceLogger.newTraceId();
                      final action = isConnected ? 'disconnect_requested' : 'connect_requested';

                      VpnTraceLogger.log(
                        traceId: traceId,
                        layer: 'client.ui.toggle_button',
                        step: 'button_pressed',
                        details: <String, Object?>{
                          'action': action,
                          'status_before_press': vpn.status.name,
                          'has_auth_token': auth.token != null,
                          'selected_server': vpn.server.publicIp,
                        },
                      );

                      vpn.toggleConnection(authToken: auth.token, traceId: traceId);
                    },
              child: SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = isConnected || isConnecting ? _pulseController.value : 0.0;

                    return CustomPaint(
                      painter: _VpnButtonPainter(status: vpn.status, pulseValue: pulse, primaryColor: primaryColor),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.6 + pulse * 0.4),
                              width: isConnected ? 2.5 : 1.5,
                            ),
                            boxShadow: isConnected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.15 + pulse * 0.15),
                                      blurRadius: 24 + pulse * 12,
                                      spreadRadius: 2 + pulse * 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isConnecting)
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                )
                              else
                                Icon(Icons.power_settings_new_rounded, size: 38, color: primaryColor),
                              const SizedBox(height: 6),
                              Text(
                                isConnected
                                    ? 'ON'
                                    : isConnecting
                                    ? '...'
                                    : 'OFF',
                                style: AppTextStyles.heading3.copyWith(
                                  color: primaryColor,
                                  letterSpacing: 3,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isConnected
                  ? 'TAP TO DISCONNECT'
                  : isConnecting
                  ? 'ESTABLISHING TUNNEL...'
                  : 'TAP TO CONNECT',
              style: AppTextStyles.monoSmall.copyWith(color: primaryColor.withValues(alpha: 0.7), letterSpacing: 2),
            ),
          ],
        );
      },
    );
  }
}

class _VpnButtonPainter extends CustomPainter {
  final ConnectionStatus status;
  final double pulseValue;
  final Color primaryColor;

  _VpnButtonPainter({required this.status, required this.pulseValue, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;

    // Outer decorative ring (dashed arc)
    final outerRadius = size.width / 2 - 4;
    final outerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15 + pulseValue * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedArc(canvas, center, outerRadius, outerPaint, 40, 0);

    // Middle arc segments
    final midRadius = size.width / 2 - 18;
    final midPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25 + pulseValue * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw 4 arc segments with gaps
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * math.pi / 2) + (math.pi / 8);
      const sweepAngle = math.pi / 4;
      canvas.drawArc(Rect.fromCircle(center: center, radius: midRadius), startAngle, sweepAngle, false, midPaint);
    }

    // Inner thin ring
    final innerRadius = size.width / 2 - 34;
    final innerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1 + pulseValue * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(center, innerRadius, innerPaint);

    // Tick marks around the outer ring
    if (isConnected || isConnecting) {
      final tickPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.3 + pulseValue * 0.2)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 36; i++) {
        final angle = (i * math.pi * 2) / 36;
        final innerPoint = Offset(
          center.dx + (outerRadius - 6) * math.cos(angle),
          center.dy + (outerRadius - 6) * math.sin(angle),
        );
        final outerPoint = Offset(
          center.dx + (outerRadius - (i % 3 == 0 ? 0 : 3)) * math.cos(angle),
          center.dy + (outerRadius - (i % 3 == 0 ? 0 : 3)) * math.sin(angle),
        );
        canvas.drawLine(innerPoint, outerPoint, tickPaint);
      }
    }

    // Corner accent dots
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final dotPositions = [
      Offset(8, 8),
      Offset(size.width - 8, 8),
      Offset(8, size.height - 8),
      Offset(size.width - 8, size.height - 8),
    ];

    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 1.5, dotPaint);
    }
  }

  void _drawDashedArc(Canvas canvas, Offset center, double radius, Paint paint, int segments, double rotation) {
    for (int i = 0; i < segments; i++) {
      final startAngle = rotation + (i * math.pi * 2) / segments;
      final sweepAngle = (math.pi * 2) / segments * 0.5;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_VpnButtonPainter oldDelegate) =>
      oldDelegate.status != status || oldDelegate.pulseValue != pulseValue || oldDelegate.primaryColor != primaryColor;
}
