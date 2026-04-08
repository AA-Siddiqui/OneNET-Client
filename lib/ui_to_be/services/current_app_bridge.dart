import 'dart:async';

import 'package:hiddify/features/connection/model/connection_status.dart' as core_connection;
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';

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
    await _readContainer.read(connectionNotifierProvider.notifier).mayConnect();
  }

  static Future<void> disconnect() async {
    await _readContainer.read(connectionNotifierProvider.notifier).abortConnection();
  }

  static Future<void> toggleConnection() async {
    await _readContainer.read(connectionNotifierProvider.notifier).toggleConnection();
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
