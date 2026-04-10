import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final vpnProvider = context.read<VpnProvider>();
    await Future.wait([Future<void>.delayed(const Duration(seconds: 2)), vpnProvider.preloadVpnNodes()]);
    if (!mounted) return;

    await _maybeShowRegionSelectionModal();
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      final loginData = authProvider.loginData;
      final userProvider = context.read<UserProvider>();
      if (loginData != null) {
        userProvider.loadFromLoginData(loginData);
      }
      if (!mounted) return;
      if (userProvider.hasActivePlan) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(Routes.noPlan);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  Future<void> _maybeShowRegionSelectionModal() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final introCompleted = container.read(Preferences.introCompleted);
    if (introCompleted) return;

    Region selectedRegion = container.read(ConfigOptions.region);
    final pickedRegion = await showModalBottomSheet<Region>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select your region', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the region that best matches your location.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDim),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: ListView(
                        children: Region.values
                            .map(
                              (region) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  selectedRegion == region
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: selectedRegion == region ? AppColors.accentBright : AppColors.textDim,
                                ),
                                title: Text(_regionLabel(region), style: AppTextStyles.bodyMedium),
                                onTap: () => setModalState(() => selectedRegion = region),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(modalContext).pop(selectedRegion),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    selectedRegion = pickedRegion ?? selectedRegion;
    await container.read(ConfigOptions.region.notifier).update(selectedRegion);
    await container.read(ConfigOptions.directDnsAddress.notifier).reset();
    await container.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en);
    await container.read(Preferences.introCompleted.notifier).update(true);
  }

  String _regionLabel(Region region) {
    switch (region) {
      case Region.ir:
        return 'Iran (ir)';
      case Region.cn:
        return 'China (cn)';
      case Region.ru:
        return 'Russia (ru)';
      case Region.af:
        return 'Afghanistan (af)';
      case Region.id:
        return 'Indonesia (id)';
      case Region.tr:
        return 'Turkey (tr)';
      case Region.br:
        return 'Brazil (br)';
      case Region.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/ui-to-be/assets/images/full_logo.png',
                width: 300,
                fit: BoxFit.contain,
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 24),
              Text(
                AppConstants.appVersionDisplay,
                style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              const SizedBox(height: 48),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentBright),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
