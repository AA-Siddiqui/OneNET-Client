import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NetworkErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const NetworkErrorView({
    super.key,
    this.message = 'No network connection.\nCheck your internet and try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textDim),
            const SizedBox(height: 16),
            Text('CONNECTION ERROR', style: AppTextStyles.heading3.copyWith(color: AppColors.textDim)),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.accentBright,
                ),
                child: Text('RETRY', style: AppTextStyles.mono),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
