import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppScaffoldWrapper extends StatefulWidget {
  final List<Widget> screens;

  const AppScaffoldWrapper({super.key, required this.screens});

  @override
  State<AppScaffoldWrapper> createState() => _AppScaffoldWrapperState();
}

class _AppScaffoldWrapperState extends State<AppScaffoldWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: widget.screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.navy,
          selectedItemColor: AppColors.accentBright,
          unselectedItemColor: AppColors.textDim,
          selectedLabelStyle: AppTextStyles.monoSmall,
          unselectedLabelStyle: AppTextStyles.monoSmall,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.shield),
              activeIcon: Icon(LucideIcons.shieldCheck),
              label: 'VPN',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings),
              activeIcon: Icon(LucideIcons.settings2),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
