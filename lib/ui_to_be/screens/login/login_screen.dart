import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/cloud_storage_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/services/url_launcher_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/gradient_background.dart';
import 'package:hiddify/ui_to_be/screens/login/widgets/brand_header.dart';
import 'package:hiddify/ui_to_be/screens/login/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      const BrandHeader().animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 40),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return LoginForm(
                            isLoading: auth.isLoading,
                            errorMessage: auth.errorMessage,
                            onSubmit: (email, password) async {
                              await auth.login(email, password);
                              if (!context.mounted) return;
                              if (auth.isAuthenticated) {
                                final userProvider = context.read<UserProvider>();
                                final loginData = auth.loginData;
                                if (loginData != null) {
                                  userProvider.loadFromLoginData(loginData);
                                }
                                if (!context.mounted) return;
                                if (userProvider.hasActivePlan) {
                                  unawaited(context.read<CloudStorageProvider>().refresh(auth.token));
                                  Navigator.of(context).pushReplacementNamed(Routes.dashboard);
                                } else {
                                  Navigator.of(context).pushReplacementNamed(Routes.noPlan);
                                }
                              }
                            },
                            onForgotPassword: () {
                              UrlLauncherService.openResetPassword();
                            },
                          );
                        },
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                      const SizedBox(height: 40),
                      Text("Don't have an account?", style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => UrlLauncherService.openSignup(),
                        child: Text(
                          'SIGN UP AT ECOMGEAR.DEV',
                          style: AppTextStyles.mono.copyWith(color: AppColors.accentBright, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
