import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final bool showGlow;
  final EdgeInsets padding;

  const GlowContainer({
    super.key,
    required this.child,
    this.borderColor = AppColors.border,
    this.showGlow = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
        boxShadow: showGlow ? [BoxShadow(color: borderColor.withValues(alpha: 0.25), blurRadius: 16)] : null,
      ),
      child: child,
    );
  }
}
