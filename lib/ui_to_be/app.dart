import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/game_session_provider.dart';
import 'package:hiddify/ui_to_be/providers/user_provider.dart';
import 'package:hiddify/ui_to_be/providers/vpn_provider.dart';
import 'package:hiddify/ui_to_be/screens/cloud_gaming/cloud_gaming_screen.dart';
import 'package:hiddify/ui_to_be/screens/dashboard/dashboard_screen.dart';
import 'package:hiddify/ui_to_be/screens/login/login_screen.dart';
import 'package:hiddify/ui_to_be/screens/no_plan_screen.dart';
import 'package:hiddify/ui_to_be/screens/settings/settings_screen.dart';
import 'package:hiddify/ui_to_be/screens/splash_screen.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';
import 'package:hiddify/ui_to_be/theme/app_theme.dart';

class OneNetApp extends StatelessWidget {
  const OneNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    CurrentAppBridge.configure(ProviderScope.containerOf(context, listen: false));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VpnProvider()),
        ChangeNotifierProvider(create: (_) => GameSessionProvider()),
      ],
      child: MaterialApp(
        title: 'eCG OneNET',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: Routes.splash,
        routes: {
          Routes.splash: (context) => const SplashScreen(),
          Routes.login: (context) => const LoginScreen(),
          Routes.noPlan: (context) => const NoPlanScreen(),
          Routes.dashboard: (context) => const DashboardScreen(),
          Routes.settings: (context) => const SettingsScreen(),
          Routes.cloudGaming: (context) => const CloudGamingScreen(),
        },
      ),
    );
  }
}
