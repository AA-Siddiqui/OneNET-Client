import 'package:flutter/material.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/status_badge.dart';
import 'package:provider/provider.dart';

const Color _oneMailBackground = Color(0xFFFFFFFF);
const Color _oneMailSurface = Color(0xFFF5F5F5);
const Color _oneMailBorder = Color(0xFFEDEDED);
const Color _oneMailPrimary = Color(0xFFF5C518);
const Color _oneMailDark = Color(0xFF4A4A4A);
const Color _oneMailMuted = Color(0xFF9A9A9A);
const Color _oneMailBlue = Color(0xFF3B82F6);

enum DashboardSuiteTab { oneNet, oneStorage, oneMail }

class DashboardHeader extends StatelessWidget {
  final DashboardSuiteTab selectedTab;
  final ValueChanged<DashboardSuiteTab> onTabChanged;

  const DashboardHeader({super.key, required this.selectedTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        final isAdmin = user.user?.isAdmin ?? false;
        final bool oneMailTheme = selectedTab == DashboardSuiteTab.oneMail;
        final Color headerBackground = oneMailTheme ? _oneMailBackground : AppColors.black.withValues(alpha: 0.95);
        final Color headerBorder = oneMailTheme ? _oneMailBorder : AppColors.border;
        final Color avatarBackground = oneMailTheme ? _oneMailSurface : AppColors.accentGlow;
        final Color avatarBorder = oneMailTheme ? _oneMailBorder : AppColors.border;
        final Color avatarIcon = oneMailTheme ? _oneMailDark : AppColors.accentBright;
        final Color tabsContainer = oneMailTheme ? _oneMailSurface : AppColors.surface.withValues(alpha: 0.7);
        final Color tabsBorder = oneMailTheme ? _oneMailBorder : AppColors.border;
        final Color tabInactive = oneMailTheme ? _oneMailMuted : AppColors.textDim;
        final String suiteLogo = oneMailTheme
            ? 'assets/ui-to-be/assets/images/onemail_full_logo_cropped.png'
            : 'assets/ui-to-be/assets/images/full_logo_cropped.png';
        final double suiteLogoWidth = oneMailTheme ? 172 : 160;
        final double suiteLogoHeight = oneMailTheme ? 60 : 56;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
          decoration: BoxDecoration(
            color: headerBackground,
            border: Border(bottom: BorderSide(color: headerBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: suiteLogoWidth,
                              height: suiteLogoHeight,
                              child: Image.asset(
                                suiteLogo,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (selectedTab == DashboardSuiteTab.oneMail)
                          StatusBadge(
                            label: isAdmin ? 'ADMIN PREVIEW' : 'EARLY SIGNUP',
                            color: isAdmin ? AppColors.gold : _oneMailPrimary,
                            backgroundColor: _oneMailSurface,
                          )
                        else
                          StatusBadge.plan(user.planLabel),
                      ],
                    ),
                    const Spacer(),
                    _RoleChip(isAdmin: isAdmin, isOneMailTheme: oneMailTheme),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarBackground,
                        border: Border.all(color: avatarBorder),
                      ),
                      child: Icon(Icons.person_outline, color: avatarIcon, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tabsContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tabsBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SuiteTabButton(
                          label: 'OneNET',
                          isSelected: selectedTab == DashboardSuiteTab.oneNet,
                          activeColor: oneMailTheme ? _oneMailBlue : AppColors.accentBright,
                          inactiveColor: tabInactive,
                          onTap: () => onTabChanged(DashboardSuiteTab.oneNet),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SuiteTabButton(
                          label: 'OneSTORAGE',
                          isSelected: selectedTab == DashboardSuiteTab.oneStorage,
                          activeColor: oneMailTheme ? _oneMailBlue : AppColors.accentBright,
                          inactiveColor: tabInactive,
                          onTap: () => onTabChanged(DashboardSuiteTab.oneStorage),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SuiteTabButton(
                          label: 'OneMAIL',
                          isSelected: selectedTab == DashboardSuiteTab.oneMail,
                          activeColor: oneMailTheme ? _oneMailPrimary : AppColors.gold,
                          inactiveColor: tabInactive,
                          onTap: () => onTabChanged(DashboardSuiteTab.oneMail),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final bool isAdmin;
  final bool isOneMailTheme;

  const _RoleChip({required this.isAdmin, required this.isOneMailTheme});

  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? AppColors.gold : (isOneMailTheme ? _oneMailBlue : AppColors.accentBright);
    final label = isAdmin ? 'ADMIN' : 'USER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isOneMailTheme ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: isOneMailTheme ? 0.28 : 0.35)),
      ),
      child: Text(label, style: AppTextStyles.monoSmall.copyWith(color: color, letterSpacing: 1)),
    );
  }
}

class _SuiteTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _SuiteTabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? activeColor.withValues(alpha: 0.55) : Colors.transparent),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.mono.copyWith(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 12,
              letterSpacing: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
