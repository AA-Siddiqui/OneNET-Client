import 'dart:async';

import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart' as core_connection;
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CurrentAppBridge {
  static ProviderContainer? _container;

  static void configure(ProviderContainer container) {
    _container = container;
  }

  static ProviderContainer get _readContainer {
    final container = _container;
    if (container == null) {
      throw StateError('CurrentAppBridge is not configured.');
    }
    return container;
  }

  static Future<List<ServerModel>> fetchServers() async {
    final profiles = await _readContainer.read(profilesNotifierProvider.future);
    if (profiles.isEmpty) {
      return <ServerModel>[ServerModel.malaysia()];
    }
    return profiles.map(_mapProfileToServer).toList(growable: false);
  }

  static Future<void> selectServer(String profileId) async {
    await _readContainer.read(profilesNotifierProvider.notifier).selectActiveProfile(profileId);
  }

  static Future<bool> selectServerByNode(ServerModel server) async {
    final profiles = await _readContainer.read(profilesNotifierProvider.future);
    if (profiles.isEmpty) {
      return false;
    }

    final matched = _findBestProfileForServer(server, profiles);
    if (matched == null) {
      return false;
    }

    await _readContainer.read(profilesNotifierProvider.notifier).selectActiveProfile(matched.id);
    return true;
  }

  static Future<ServerModel?> currentActiveServer() async {
    final profile = await _readContainer.read(activeProfileProvider.future);
    if (profile == null) {
      return null;
    }
    return _mapProfileToServer(profile);
  }

  static Stream<ServerModel?> watchActiveServer() {
    final controller = StreamController<ServerModel?>();
    final subscription = _readContainer.listen<AsyncValue<ProfileEntity?>>(activeProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      controller.add(profile == null ? null : _mapProfileToServer(profile));
    }, fireImmediately: true);

    controller.onCancel = () {
      subscription.close();
      controller.close();
    };

    return controller.stream;
  }

  static Future<void> connect() async {
    final notifier = _readContainer.read(connectionNotifierProvider.notifier);
    final state = _readContainer.read(connectionNotifierProvider);

    if (state.hasError) {
      await notifier.toggleConnection();
      return;
    }

    if (state.valueOrNull case core_connection.Disconnected()) {
      await notifier.toggleConnection();
    }
  }

  static Future<void> disconnect() async {
    if (_readContainer.read(connectionNotifierProvider).valueOrNull case core_connection.Connected()) {
      await _readContainer.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }

  static Future<void> toggleConnection() async {
    await _readContainer.read(connectionNotifierProvider.notifier).toggleConnection();
  }

  static Future<void> applyProvisionedConfig(String configContent) async {
    try {
      final normalized = configContent.trim();
      if (normalized.isEmpty) {
        throw const CurrentAppBridgeException('VPN configuration is empty.');
      }

      final profileRepository = await _readContainer.read(profileRepositoryProvider.future);
      final activeProfile = await _readContainer.read(activeProfileProvider.future);

      final result = activeProfile == null
          ? await profileRepository.addLocal(normalized).run()
          : await profileRepository.offlineUpdate(activeProfile, normalized).run();

      result.match(
        (failure) => throw CurrentAppBridgeException('Failed to apply VPN configuration: $failure'),
        (_) => null,
      );
    } on CurrentAppBridgeException {
      rethrow;
    } catch (error) {
      throw CurrentAppBridgeException('Failed to apply VPN configuration: $error');
    }
  }

  static Future<void> showAddProfile({String? url}) async {
    await _readContainer.read(bottomSheetsNotifierProvider.notifier).showAddProfile(url: url);
  }

  static Future<void> showProfilesOverview() async {
    await _readContainer.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
  }

  static ConnectionStatus currentConnectionStatus() {
    return _mapConnectionStatus(_readContainer.read(connectionNotifierProvider).valueOrNull);
  }

  static Stream<ConnectionStatus> watchConnectionStatus() {
    final controller = StreamController<ConnectionStatus>();
    final subscription = _readContainer.listen<AsyncValue<core_connection.ConnectionStatus>>(
      connectionNotifierProvider,
      (previous, next) => controller.add(_mapConnectionStatus(next.valueOrNull)),
      fireImmediately: true,
    );

    controller.onCancel = () {
      subscription.close();
      controller.close();
    };

    return controller.stream;
  }

  static Stream<SystemInfo> watchStats() {
    final controller = StreamController<SystemInfo>();
    final subscription = _readContainer.listen<AsyncValue<SystemInfo>>(statsNotifierProvider, (previous, next) {
      controller.add(next.valueOrNull ?? SystemInfo.create());
    }, fireImmediately: true);

    controller.onCancel = () {
      subscription.close();
      controller.close();
    };

    return controller.stream;
  }

  static ServerModel _mapProfileToServer(ProfileEntity profile) {
    final host = switch (profile) {
      RemoteProfileEntity(:final url) => Uri.tryParse(url)?.host ?? '',
      LocalProfileEntity() => '',
    };

    final region = _firstToken(profile.name, fallback: 'Global');
    final nodeId = profile.id.length >= 8 ? profile.id.substring(0, 8).toUpperCase() : profile.id.toUpperCase();

    return ServerModel(id: profile.id, name: profile.name, region: region, nodeId: nodeId, publicIp: host);
  }

  static ProfileEntity? _findBestProfileForServer(ServerModel server, List<ProfileEntity> profiles) {
    ProfileEntity? best;
    var bestScore = 0;

    for (final profile in profiles) {
      final score = _scoreProfileMatch(server, profile);
      if (score > bestScore) {
        bestScore = score;
        best = profile;
      }
    }

    return best;
  }

  static int _scoreProfileMatch(ServerModel server, ProfileEntity profile) {
    final normalizedId = _normalize(server.id);
    final normalizedName = _normalize(server.name);
    final normalizedRegion = _normalize(server.region);
    final normalizedNodeId = _normalize(server.nodeId);
    final normalizedIp = _normalize(server.publicIp);
    final normalizedProfileId = _normalize(profile.id);
    final normalizedProfileName = _normalize(profile.name);

    var score = 0;

    if (normalizedId.isNotEmpty && normalizedId == normalizedProfileId) {
      score += 200;
    }

    if (normalizedName.isNotEmpty && normalizedName == normalizedProfileName) {
      score += 120;
    }

    if (normalizedName.isNotEmpty && normalizedProfileName.contains(normalizedName)) {
      score += 70;
    }

    if (normalizedRegion.isNotEmpty && normalizedProfileName.contains(normalizedRegion)) {
      score += 45;
    }

    if (normalizedNodeId.isNotEmpty && normalizedProfileName.contains(normalizedNodeId)) {
      score += 35;
    }

    if (profile case RemoteProfileEntity(:final url)) {
      final normalizedHost = _normalize(_safeHost(url));

      if (normalizedIp.isNotEmpty && normalizedHost == normalizedIp) {
        score += 180;
      }

      if (normalizedNodeId.isNotEmpty && normalizedHost.contains(normalizedNodeId)) {
        score += 90;
      }

      if (normalizedName.isNotEmpty && normalizedHost.contains(normalizedName)) {
        score += 65;
      }

      if (normalizedRegion.isNotEmpty && normalizedHost.contains(normalizedRegion)) {
        score += 35;
      }
    }

    return score;
  }

  static String _safeHost(String url) {
    return Uri.tryParse(url)?.host ?? '';
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static String _firstToken(String input, {required String fallback}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final split = trimmed.split(RegExp(r'\s+'));
    return split.isEmpty ? fallback : split.first;
  }

  static ConnectionStatus _mapConnectionStatus(core_connection.ConnectionStatus? status) {
    return switch (status) {
      core_connection.Connected() => ConnectionStatus.connected,
      core_connection.Connecting() => ConnectionStatus.connecting,
      core_connection.Disconnecting() => ConnectionStatus.connecting,
      core_connection.Disconnected() => ConnectionStatus.disconnected,
      null => ConnectionStatus.disconnected,
    };
  }
}

class CurrentAppBridgeException implements Exception {
  final String message;
  const CurrentAppBridgeException(this.message);

  @override
  String toString() => message;
}
