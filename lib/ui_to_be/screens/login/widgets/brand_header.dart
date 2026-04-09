import 'package:flutter/material.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/ui-to-be/assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain),
        const SizedBox(height: 8),
        Text('OneNET', style: AppTextStyles.headingAccent.copyWith(fontSize: 40)),
        const SizedBox(height: 16),
        Text('// AUTHENTICATE', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
      ],
    );
  }
}
