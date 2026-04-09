import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';

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
