import 'package:flutter/material.dart';
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';

class AppVersionDisplay extends StatelessWidget {
  const AppVersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/ui-to-be/new_assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(AppConstants.appFullName, style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
          const SizedBox(height: 2),
          Text(
            AppConstants.appVersionDisplay,
            style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim.withValues(alpha: 0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
