import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset('assets/images/logo.svg', width: 80, height: 80),
        const SizedBox(height: 8),
        Text('OneNET', style: AppTextStyles.headingAccent.copyWith(fontSize: 40)),
        const SizedBox(height: 16),
        Text('// AUTHENTICATE', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
      ],
    );
  }
}
