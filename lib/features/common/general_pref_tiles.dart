import 'package:flutter/material.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocalePrefTile extends ConsumerWidget {
  const LocalePrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final locale = ref.watch(localePreferencesProvider);
    return ListTile(
      title: Text(t.pages.settings.general.locale),
      subtitle: Text(locale.localeName),
      leading: const Icon(Icons.translate_rounded),
      onTap: () async {
        final selectedLocale = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingPicker<AppLocale>(
              title: t.pages.settings.general.locale,
              selected: locale,
              onReset: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en),
              options: AppLocale.values,
              getTitle: (e) => e.localeName,
            );
        if (selectedLocale != null) {
          await ref.read(localePreferencesProvider.notifier).changeLocale(selectedLocale);
        }
      },
    );
  }
}

class EnableAnalyticsPrefTile extends ConsumerWidget {
  const EnableAnalyticsPrefTile({super.key, this.onChanged});

  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final enabled = ref.watch(analyticsControllerProvider).requireValue;

    return SwitchListTile.adaptive(
      title: Text(t.pages.settings.general.enableAnalytics),
      subtitle: Text(t.pages.settings.general.enableAnalyticsMsg, style: Theme.of(context).textTheme.bodySmall),
      secondary: const Icon(Icons.analytics_rounded),
      value: enabled,
      onChanged: (value) async {
        if (onChanged != null) {
          return onChanged!(value);
        }
        if (enabled) {
          await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
        } else {
          await ref.read(analyticsControllerProvider.notifier).enableAnalytics();
        }
      },
    );
  }
}

class ThemeModePrefTile extends ConsumerWidget {
  const ThemeModePrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final themeMode = ref.watch(themePreferencesProvider);

    return ListTile(
      title: Text(t.pages.settings.general.themeMode),
      subtitle: Text(themeMode.present(t)),
      leading: Icon(switch (ref.watch(themePreferencesProvider)) {
        AppThemeMode.system => Icons.auto_awesome_rounded,
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
        AppThemeMode.black => Icons.contrast_rounded,
      }),
      onTap: () async {
        final selectedThemeMode = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingPicker<AppThemeMode>(
              title: t.pages.settings.general.themeMode,
              selected: themeMode,
              onReset: () => ref.read(themePreferencesProvider.notifier).changeThemeMode(AppThemeMode.system),
              options: AppThemeMode.values,
              getTitle: (e) => e.present(t),
            );
        if (selectedThemeMode != null) {
          await ref.read(themePreferencesProvider.notifier).changeThemeMode(selectedThemeMode);
        }
      },
    );
  }
}

class ClosingPrefTile extends ConsumerWidget {
  const ClosingPrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final action = ref.watch(Preferences.actionAtClose);
    final selectedAction = switch (action) {
      ActionsAtClosing.hide => {ActionsAtClosing.hide},
      ActionsAtClosing.exit => {ActionsAtClosing.exit},
      ActionsAtClosing.ask => <ActionsAtClosing>{},
    };
    final subtitle = switch (action) {
      ActionsAtClosing.hide => "Hide to system tray",
      ActionsAtClosing.exit => "Exit the application",
      ActionsAtClosing.ask => t.dialogs.windowClosing.askEachTime,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.logout_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.dialogs.windowClosing.alertMessage, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ActionsAtClosing>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ActionsAtClosing.hide,
                  icon: Icon(Icons.visibility_off_rounded),
                  label: Text("Hide to tray"),
                ),
                ButtonSegment(value: ActionsAtClosing.exit, icon: Icon(Icons.close_rounded), label: Text("Exit app")),
              ],
              selected: selectedAction,
              onSelectionChanged: (selection) async {
                if (selection.isEmpty) return;
                await ref.read(Preferences.actionAtClose.notifier).update(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
