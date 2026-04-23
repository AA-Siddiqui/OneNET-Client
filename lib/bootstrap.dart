import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';

import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/riverpod_observer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hiddify/ui_to_be/services/release_service.dart';
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:version/version.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> lazyBootstrap(WidgetsBinding widgetsBinding, Environment env) async {
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(overrides: [environmentProvider.overrideWithValue(env)]);

  await _init("directories", () => container.read(appDirectoriesProvider.future));
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init("app info", () => container.read(appInfoProvider.future));
  await _init("preferences", () => container.read(sharedPreferencesProvider.future));

  final enableAnalytics = await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init("analytics", () => container.read(analyticsControllerProvider.notifier).enableAnalytics());
  }

  await _init("preferences migration", () async {
    try {
      await PreferencesMigration(sharedPreferences: container.read(sharedPreferencesProvider).requireValue).migrate();
    } catch (e, stackTrace) {
      Logger.bootstrap.error("preferences migration failed", e, stackTrace);
      if (env == Environment.dev) rethrow;
      Logger.bootstrap.info("clearing preferences");
      await container.read(sharedPreferencesProvider).requireValue.clear();
    }
  });

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init("window controller", () => container.read(windowNotifierProvider.future));

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap.debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");
    if (!silentStart) {
      await container.read(windowNotifierProvider.notifier).show(focus: false);
    } else {
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }
    await _init("auto start service", () => container.read(autoStartNotifierProvider.future));
  }
  await _init("logs repository", () => container.read(logRepositoryProvider.future));
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init("profile repository", () => container.read(profileRepositoryProvider.future));

  await _init("translations", () => container.read(translationsProvider.future));

  await _safeInit("active profile", () => container.read(activeProfileProvider.future), timeout: 1000);
  await _init("hiddify-core", () => container.read(hiddifyCoreServiceProvider).init());

  if (!kIsWeb) {
    // await _safeInit(
    //   "deep link service",
    //   () => container.read(deepLinkNotifierProvider.future),
    //   timeout: 1000,
    // );

    if (PlatformUtils.isDesktop) {
      await _safeInit("system tray", () => container.read(systemTrayNotifierProvider.future), timeout: 1000);
    }

    if (PlatformUtils.isAndroid) {
      await _safeInit("android display mode", () async {
        await FlutterDisplayMode.setHighRefreshRate();
      });
    }
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(
    ProviderScope(
      parent: container,
      observers: [RiverpodObserver()],
      child: SentryUserInteractionWidget(child: const App()),
    ),
  );

  // After the first frame, check for DB-driven release info and show update UI if needed.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkDbReleaseAndShowIfNeeded(container);
  });

  if (!kIsWeb) {
    FlutterNativeSplash.remove();
  }
  // SentryFlutter.s(DateTime.now().toUtc());
}

Future<void> _checkDbReleaseAndShowIfNeeded(ProviderContainer container) async {
  try {
    final release = await ReleaseService.fetchLatestRelease();
    if (release == null) return;

    Version? latest;
    Version? current;
    try {
      latest = Version.parse(release.version);
    } catch (_) {
      return; // ignore unparsable remote version
    }
    try {
      current = Version.parse(AppConstants.appVersion);
    } catch (_) {
      return;
    }

    if (latest <= current) return;

    final now = DateTime.now().toUtc();
    final pastLastUse = release.lastUsableDate != null && now.isAfter(release.lastUsableDate!);

    final ctx = rootNavKey.currentContext;
    if (ctx == null) return;

    // Build dialog content
    final title = pastLastUse ? 'Update required' : 'Update available';
    final message = pastLastUse
        ? 'This app version is no longer supported. Please update to continue.'
        : 'A new version (${release.version}) is available. Would you like to update now?';

    // show a blocking dialog for required update, otherwise allow dismiss
    await showDialog<void>(
      context: ctx,
      barrierDismissible: !pastLastUse,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              final url = (release.downloadUrl != null && release.downloadUrl!.isNotEmpty)
                  ? release.downloadUrl!
                  : AppConstants.portalDownloadsUrl;
              await UriUtils.tryLaunch(Uri.parse(url));
            },
            child: const Text('Update now'),
          ),
          if (!pastLastUse) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
          if (pastLastUse)
            TextButton(
              onPressed: () {
                // force quit
                exit(0);
              },
              child: const Text('Exit'),
            ),
        ],
      ),
    );
  } catch (_) {
    // ignore
  }
}

Future<T> _init<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}
