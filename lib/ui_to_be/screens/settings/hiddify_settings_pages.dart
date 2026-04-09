import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/features/settings/notifier/warp_option/warp_option_notifier.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/ui_to_be/config/routes.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:humanizer/humanizer.dart';
import 'package:network_info_plus/network_info_plus.dart';

class OneNetConfigActionsPage extends HookConsumerWidget {
  const OneNetConfigActionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.title)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.content_paste_rounded),
            title: Text(t.pages.settings.options.import.clipboard),
            onTap: () async {
              final shouldImport = await ref
                  .read(dialogNotifierProvider.notifier)
                  .showConfirmation(
                    title: t.common.msg.import.confirm,
                    message: t.dialogs.confirmation.settings.import.msg,
                  );
              if (shouldImport) {
                await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_open_rounded),
            title: Text(t.pages.settings.options.import.file),
            onTap: () async {
              final shouldImport = await ref
                  .read(dialogNotifierProvider.notifier)
                  .showConfirmation(
                    title: t.common.msg.import.confirm,
                    message: t.dialogs.confirmation.settings.import.msg,
                  );
              if (shouldImport) {
                await ref.read(configOptionNotifierProvider.notifier).importFromJsonFile();
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(t.pages.settings.options.export.anonymousToClipboard),
            onTap: () async {
              await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.save_alt_rounded),
            title: Text(t.pages.settings.options.export.anonymousToFile),
            onTap: () async {
              await ref.read(configOptionNotifierProvider.notifier).exportJsonFile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_rounded),
            title: Text(t.pages.settings.options.export.allToClipboard),
            onTap: () async {
              await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard(excludePrivate: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: Text(t.pages.settings.options.export.allToFile),
            onTap: () async {
              await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(excludePrivate: false);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: Text(t.pages.settings.options.reset),
            onTap: () async {
              await ref.read(configOptionNotifierProvider.notifier).resetOption();
            },
          ),
          if (PlatformUtils.isIOS)
            ListTile(
              leading: const Icon(Icons.autorenew_rounded),
              title: Text(t.pages.settings.resetTunnel),
              onTap: () async {
                await ref.read(resetTunnelNotifierProvider.notifier).run();
              },
            ),
        ],
      ),
    );
  }
}

class OneNetGeneralSettingsPage extends HookConsumerWidget {
  const OneNetGeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.general.title)),
      body: ListView(
        children: [
          const LocalePrefTile(),
          const ThemeModePrefTile(),
          const EnableAnalyticsPrefTile(),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.general.autoIpCheck),
            value: ref.watch(Preferences.autoCheckIp),
            secondary: const Icon(Icons.flag_rounded),
            onChanged: ref.read(Preferences.autoCheckIp.notifier).update,
          ),
          if (PlatformUtils.isAndroid) ...[
            SwitchListTile.adaptive(
              title: Text(t.pages.settings.general.dynamicNotification),
              secondary: const Icon(Icons.speed_rounded),
              value: ref.watch(Preferences.dynamicNotification),
              onChanged: ref.read(Preferences.dynamicNotification.notifier).update,
            ),
            SwitchListTile.adaptive(
              title: Text(t.pages.settings.general.hapticFeedback),
              secondary: const Icon(Icons.vibration_rounded),
              value: ref.watch(hapticServiceProvider),
              onChanged: ref.read(hapticServiceProvider.notifier).updatePreference,
            ),
          ],
          if (PlatformUtils.isDesktop) ...[
            const ClosingPrefTile(),
            SwitchListTile.adaptive(
              title: Text(t.pages.settings.general.autoStart),
              secondary: const Icon(Icons.auto_mode_rounded),
              value: ref.watch(autoStartNotifierProvider).asData!.value,
              onChanged: (value) async => value
                  ? await ref.read(autoStartNotifierProvider.notifier).enable()
                  : await ref.read(autoStartNotifierProvider.notifier).disable(),
            ),
            SwitchListTile.adaptive(
              title: Text(t.pages.settings.general.silentStart),
              secondary: const Icon(Icons.visibility_off_rounded),
              value: ref.watch(Preferences.silentStart),
              onChanged: ref.read(Preferences.silentStart.notifier).update,
            ),
          ],
          if (PlatformUtils.isAndroid) const BatteryOptimizationWidget(),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.general.memoryLimit),
            subtitle: Text(t.pages.settings.general.memoryLimitMsg),
            secondary: const Icon(Icons.memory_rounded),
            value: !ref.watch(Preferences.disableMemoryLimit),
            onChanged: (value) async => await ref.read(Preferences.disableMemoryLimit.notifier).update(!value),
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.general.debugMode),
            secondary: const Icon(Icons.bug_report_rounded),
            value: ref.watch(debugModeNotifierProvider),
            onChanged: (value) async {
              if (value) {
                await ref
                    .read(dialogNotifierProvider.notifier)
                    .showOk(t.pages.settings.general.debugMode, t.pages.settings.general.debugModeMsg);
              }
              await ref.read(debugModeNotifierProvider.notifier).update(value);
            },
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.logLevel),
            preferences: ref.watch(ConfigOptions.logLevel.notifier),
            choices: LogLevel.choices,
            title: t.pages.settings.general.logLevel,
            icon: Icons.description_rounded,
            presentChoice: (value) => value.name.toUpperCase(),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.connectionTestUrl),
            preferences: ref.watch(ConfigOptions.connectionTestUrl.notifier),
            title: t.pages.settings.general.connectionTestUrl,
            icon: Icons.link_rounded,
          ),
          ListTile(
            title: Text(t.pages.settings.general.urlTestInterval),
            subtitle: Text(ref.watch(ConfigOptions.urlTestInterval).toApproximateTime(isRelativeToNow: false)),
            leading: const Icon(Icons.timer_rounded),
            onTap: () async {
              final value = await ref
                  .read(dialogNotifierProvider.notifier)
                  .showSettingSlider(
                    title: t.pages.settings.general.urlTestInterval,
                    initialValue: ref.watch(ConfigOptions.urlTestInterval).inMinutes.coerceIn(0, 60).toDouble(),
                    onReset: ref.read(ConfigOptions.urlTestInterval.notifier).reset,
                    min: 1,
                    max: 60,
                    divisions: 60,
                    labelGen: (sliderValue) =>
                        Duration(minutes: sliderValue.toInt()).toApproximateTime(isRelativeToNow: false),
                  );
              if (value == null) {
                return;
              }
              await ref.read(ConfigOptions.urlTestInterval.notifier).update(Duration(minutes: value.toInt()));
            },
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.clashApiPort),
            preferences: ref.watch(ConfigOptions.clashApiPort.notifier),
            title: t.pages.settings.general.clashApiPort,
            icon: Icons.api_rounded,
            validateInput: isPort,
            digitsOnly: true,
            inputToValue: int.tryParse,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.general.useXrayCoreWhenPossible),
            subtitle: Text(t.pages.settings.general.useXrayCoreWhenPossibleMsg),
            secondary: const Icon(Icons.extension_rounded),
            value: ref.watch(ConfigOptions.useXrayCoreWhenPossible),
            onChanged: ref.read(ConfigOptions.useXrayCoreWhenPossible.notifier).update,
          ),
        ],
      ),
    );
  }
}

class OneNetRouteOptionsPage extends HookConsumerWidget {
  const OneNetRouteOptionsPage({super.key});

  void _openPerAppProxy(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.settingsPerAppProxy);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final perAppProxy = ref.watch(Preferences.perAppProxyMode).enabled;

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.routing.title)),
      body: ListView(
        children: [
          if (PlatformUtils.isAndroid)
            ListTile(
              title: Text(t.pages.settings.routing.perAppProxy.title),
              leading: const Icon(Icons.apps_rounded),
              trailing: Switch(
                value: perAppProxy,
                onChanged: (value) async {
                  final newMode = perAppProxy ? PerAppProxyMode.off : PerAppProxyMode.exclude;
                  await ref.read(Preferences.perAppProxyMode.notifier).update(newMode);
                  if (!perAppProxy && context.mounted) {
                    _openPerAppProxy(context);
                  }
                },
              ),
              onTap: () async {
                if (!perAppProxy) {
                  await ref.read(Preferences.perAppProxyMode.notifier).update(PerAppProxyMode.exclude);
                }
                if (context.mounted) {
                  _openPerAppProxy(context);
                }
              },
            ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.region),
            preferences: ref.watch(ConfigOptions.region.notifier),
            choices: Region.values,
            title: t.pages.settings.routing.region,
            showFlag: true,
            icon: Icons.place_rounded,
            presentChoice: (value) => value.present(t),
            onChanged: (val) async {
              await ref.read(ConfigOptions.directDnsAddress.notifier).reset();
              final autoRegion = ref.read(Preferences.autoAppsSelectionRegion);
              final mode = ref.read(Preferences.perAppProxyMode).toAppProxy();
              if (autoRegion != val &&
                  autoRegion != null &&
                  val != Region.other &&
                  mode != null &&
                  PlatformUtils.isAndroid) {
                await ref
                    .read(dialogNotifierProvider.notifier)
                    .showOk(
                      t.pages.settings.routing.perAppProxy.autoSelection.dialog.title,
                      t.pages.settings.routing.perAppProxy.autoSelection.dialog.msg(region: val.name),
                    );
                await ref.read(PerAppProxyProvider(mode).notifier).clearAutoSelected();
              }
            },
          ),
          ChoicePreferenceWidget(
            title: t.pages.settings.routing.balancerStrategy.title,
            icon: Icons.balance_rounded,
            selected: ref.watch(ConfigOptions.balancerStrategy),
            preferences: ref.watch(ConfigOptions.balancerStrategy.notifier),
            choices: BalancerStrategy.values,
            presentChoice: (value) => value.present(t),
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.routing.blockAds),
            secondary: const Icon(Icons.block_rounded),
            value: ref.watch(ConfigOptions.blockAds),
            onChanged: ref.read(ConfigOptions.blockAds.notifier).update,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.routing.bypassLan),
            secondary: const Icon(Icons.call_split_rounded),
            value: ref.watch(ConfigOptions.bypassLan),
            onChanged: ref.read(ConfigOptions.bypassLan.notifier).update,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.routing.resolveDestination),
            secondary: const Icon(Icons.security_rounded),
            value: ref.watch(ConfigOptions.resolveDestination),
            onChanged: ref.read(ConfigOptions.resolveDestination.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.ipv6Mode),
            preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
            choices: IPv6Mode.values,
            title: t.pages.settings.routing.ipv6Route,
            icon: Icons.looks_6_rounded,
            presentChoice: (value) => value.present(t),
          ),
        ],
      ),
    );
  }
}

class OneNetDnsOptionsPage extends HookConsumerWidget {
  const OneNetDnsOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.dns.title)),
      body: ListView(
        children: [
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.remoteDnsAddress),
            icon: Icons.vpn_lock_rounded,
            preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
            title: t.pages.settings.dns.remoteDns,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
            preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
            choices: DomainStrategy.values,
            title: t.pages.settings.dns.remoteDnsDomainStrategy,
            icon: Icons.sync_alt_rounded,
            presentChoice: (value) => value.present(t),
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.dns.enableFakeDns),
            secondary: const Icon(Icons.private_connectivity_rounded),
            value: ref.watch(ConfigOptions.enableFakeDns),
            onChanged: ref.read(ConfigOptions.enableFakeDns.notifier).update,
          ),
          ValuePreferenceWidget(
            title: t.pages.settings.dns.directDns,
            icon: Icons.public_rounded,
            value: ref.watch(ConfigOptions.directDnsAddress),
            preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
            preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
            choices: DomainStrategy.values,
            title: t.pages.settings.dns.directDnsDomainStrategy,
            icon: Icons.sync_alt_rounded,
            presentChoice: (value) => value.present(t),
          ),
        ],
      ),
    );
  }
}

class OneNetInboundOptionsPage extends HookConsumerWidget {
  const OneNetInboundOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.inbound.title)),
      body: ListView(
        children: [
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.serviceMode),
            preferences: ref.watch(ConfigOptions.serviceMode.notifier),
            choices: ServiceMode.choices,
            title: t.pages.settings.inbound.serviceMode,
            icon: Icons.tune_rounded,
            presentChoice: (value) => value.present(t),
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.inbound.strictRoute),
            secondary: const Icon(Icons.merge_rounded),
            value: ref.watch(ConfigOptions.strictRoute),
            onChanged: ref.read(ConfigOptions.strictRoute.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.tunImplementation),
            preferences: ref.watch(ConfigOptions.tunImplementation.notifier),
            choices: TunImplementation.values,
            title: t.pages.settings.inbound.tunImplementation,
            icon: Icons.trip_origin_rounded,
            presentChoice: (value) => value.name,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.mixedPort),
            preferences: ref.watch(ConfigOptions.mixedPort.notifier),
            title: t.pages.settings.inbound.mixedPort,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            digitsOnly: true,
            validateInput: isPort,
          ),
          if (PlatformUtils.isLinux)
            ValuePreferenceWidget(
              value: ref.watch(ConfigOptions.tproxyPort),
              preferences: ref.watch(ConfigOptions.tproxyPort.notifier),
              title: t.pages.settings.inbound.tproxyPort,
              icon: Icons.device_hub_rounded,
              inputToValue: int.tryParse,
              digitsOnly: true,
              validateInput: isPort,
            ),
          if (PlatformUtils.isLinux || PlatformUtils.isMacOS)
            ValuePreferenceWidget(
              value: ref.watch(ConfigOptions.redirectPort),
              preferences: ref.watch(ConfigOptions.redirectPort.notifier),
              title: t.pages.settings.inbound.redirectPort,
              icon: Icons.device_hub_rounded,
              inputToValue: int.tryParse,
              digitsOnly: true,
              validateInput: isPort,
            ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.directPort),
            preferences: ref.watch(ConfigOptions.directPort.notifier),
            title: t.pages.settings.inbound.directPort,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            digitsOnly: true,
            validateInput: isPort,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.inbound.allowConnectionFromLan),
            secondary: const Icon(Icons.share_rounded),
            value: ref.watch(ConfigOptions.allowConnectionFromLan),
            onChanged: (bool value) async {
              await ref.read(ConfigOptions.allowConnectionFromLan.notifier).update(value);
              if (!value) {
                return;
              }

              final ip = await NetworkInfo().getWifiIP();
              if (ip == null) {
                return;
              }

              final port = ref.read(ConfigOptions.mixedPort);
              final link = '#profile-title: LAN only\nsocks://$ip:$port#LAN only';
              final message = 'socks://$ip:$port';
              await ref.read(dialogNotifierProvider.notifier).showQrCode(link, message: message);
            },
          ),
        ],
      ),
    );
  }
}

class OneNetTlsTricksPage extends HookConsumerWidget {
  const OneNetTlsTricksPage({super.key});

  String _presentFragmentPackets(TranslationsEn t, String value) => switch (value) {
    'tlshello' => t.pages.settings.tlsTricks.packetsTlsHello,
    '1-1' => t.pages.settings.tlsTricks.packets1_1,
    '1-2' => t.pages.settings.tlsTricks.packets1_2,
    '1-3' => t.pages.settings.tlsTricks.packets1_3,
    '1-4' => t.pages.settings.tlsTricks.packets1_4,
    '1-5' => t.pages.settings.tlsTricks.packets1_5,
    _ => value,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final canChangeOption = ref.watch(ConfigOptions.enableTlsFragment);

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.tlsTricks.title)),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.enable),
            value: ref.watch(ConfigOptions.enableTlsFragment),
            secondary: const Icon(Icons.content_cut_rounded),
            onChanged: ref.read(ConfigOptions.enableTlsFragment.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.fragmentPackets),
            preferences: ref.watch(ConfigOptions.fragmentPackets.notifier),
            choices: const ['tlshello', '1-1', '1-2', '1-3', '1-4', '1-5'],
            title: t.pages.settings.tlsTricks.packets,
            icon: Icons.layers_rounded,
            presentChoice: (value) => _presentFragmentPackets(t, value),
            enabled: canChangeOption,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsFragmentSize),
            preferences: ref.watch(ConfigOptions.tlsFragmentSize.notifier),
            title: t.pages.settings.tlsTricks.size,
            icon: Icons.straighten_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsFragmentSleep),
            preferences: ref.watch(ConfigOptions.tlsFragmentSleep.notifier),
            title: t.pages.settings.tlsTricks.sleep,
            icon: Icons.snooze_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.mixedSniCase.enable),
            value: ref.watch(ConfigOptions.enableTlsMixedSniCase),
            secondary: const Icon(Icons.text_fields_rounded),
            onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsMixedSniCase.notifier).update : null,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.padding.enable),
            value: ref.watch(ConfigOptions.enableTlsPadding),
            secondary: const Icon(Icons.expand_rounded),
            onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsPadding.notifier).update : null,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsPaddingSize),
            preferences: ref.watch(ConfigOptions.tlsPaddingSize.notifier),
            title: t.pages.settings.tlsTricks.padding.size,
            icon: Icons.straighten_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.format(),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
        ],
      ),
    );
  }
}

class OneNetWarpOptionsPage extends HookConsumerWidget {
  const OneNetWarpOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final warpOptions = ref.watch(warpOptionNotifierProvider);
    final isWarpEnabled = ref.watch(ConfigOptions.enableWarp);

    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.warp.title)),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.warp.enable),
            value: isWarpEnabled,
            secondary: const Icon(Icons.cloud_rounded),
            onChanged: (value) async {
              await ref.read(ConfigOptions.enableWarp.notifier).update(value);
              if (value) {
                await ref.read(warpOptionNotifierProvider.notifier).genWarps();
              }
            },
          ),
          ListTile(
            title: Text(t.pages.settings.warp.generateConfig),
            subtitle: !isWarpEnabled
                ? null
                : warpOptions.when(
                    loading: () => null,
                    data: (_) => null,
                    error: (_, _) =>
                        Text(t.pages.settings.warp.missingConfig, style: TextStyle(color: theme.colorScheme.error)),
                  ),
            trailing: warpOptions.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                : null,
            leading: const Icon(Icons.build_rounded),
            enabled: isWarpEnabled && !warpOptions.isLoading,
            onTap: warpOptions.isLoading
                ? null
                : () async {
                    await ref.read(warpOptionNotifierProvider.notifier).genWarps();
                  },
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.warpDetourMode),
            preferences: ref.watch(ConfigOptions.warpDetourMode.notifier),
            enabled: isWarpEnabled,
            choices: WarpDetourMode.values,
            title: t.pages.settings.warp.detourMode,
            icon: Icons.alt_route_rounded,
            presentChoice: (value) => value.present(t),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpLicenseKey),
            preferences: ref.watch(ConfigOptions.warpLicenseKey.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.licenseKey,
            icon: Icons.key_rounded,
            presentValue: (value) => value.isEmpty ? t.common.notSet : value,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpCleanIp),
            preferences: ref.watch(ConfigOptions.warpCleanIp.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.cleanIp,
            icon: Icons.auto_awesome_rounded,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpPort),
            preferences: ref.watch(ConfigOptions.warpPort.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.port,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            validateInput: isPort,
            digitsOnly: true,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoise),
            preferences: ref.watch(ConfigOptions.warpNoise.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.noise.count,
            icon: Icons.web_stories_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseMode),
            preferences: ref.watch(ConfigOptions.warpNoiseMode.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.noise.mode,
            icon: Icons.mode_standby_rounded,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseSize),
            preferences: ref.watch(ConfigOptions.warpNoiseSize.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.noise.size,
            icon: Icons.settings_ethernet_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseDelay),
            preferences: ref.watch(ConfigOptions.warpNoiseDelay.notifier),
            enabled: isWarpEnabled,
            title: t.pages.settings.warp.noise.delay,
            icon: Icons.schedule_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
        ],
      ),
    );
  }
}
