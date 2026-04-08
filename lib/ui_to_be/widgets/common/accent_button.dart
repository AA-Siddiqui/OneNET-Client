import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const AccentButton({super.key, required this.label, this.onPressed, this.isLoading = false, this.fullWidth = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null ? const LinearGradient(colors: [AppColors.accent, AppColors.accentBright]) : null,
          color: onPressed == null ? AppColors.textDim.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(4),
          boxShadow: onPressed != null
              ? const [BoxShadow(color: AppColors.accentGlow, blurRadius: 16, spreadRadius: 2)]
              : null,
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textBright),
                )
              : Text(
                  label,
                  style: AppTextStyles.heading3.copyWith(
                    color: onPressed != null ? AppColors.textBright : AppColors.textDim,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
