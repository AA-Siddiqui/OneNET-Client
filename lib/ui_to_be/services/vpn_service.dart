import 'dart:convert';

import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';
import 'package:http/http.dart' as http;

class VpnService {
  // Kept for compatibility with older ui_to_be code paths.
  static Future<String> connect({
    required String token,
    required String serverIp,
    required String traceId,
    String? preferredProfileName,
    int attempt = 1,
  }) async {
    final provisioned = await provisionConnection(token: token, serverIp: serverIp, traceId: traceId, attempt: attempt);
    await applyProvisionedConfig(
      provisioned.config,
      fallbackContent: provisioned.serverConfig,
      preferredProfileName: preferredProfileName,
    );
    await CurrentAppBridge.connect();
    return provisioned.assignedIp ?? '';
  }

  static Future<VpnConnectResult> provisionConnection({
    required String token,
    required String serverIp,
    required String traceId,
    int attempt = 1,
  }) async {
    final normalizedToken = token.trim();
    final normalizedServerIp = serverIp.trim();
    if (normalizedToken.isEmpty) {
      throw const VpnException('Please sign in to connect.');
    }
    if (normalizedServerIp.isEmpty) {
      throw const VpnException('Please select a VPN server.');
    }

    final response = await http.post(
      Uri.parse(AppConstants.vpnConnectEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': 'Bearer $normalizedToken',
        'apikey': AppConstants.supabaseAnonKey,
        'x-trace-id': traceId,
        'x-connect-attempt': '$attempt',
        'x-client-ts': DateTime.now().toUtc().toIso8601String(),
      },
      body: jsonEncode({'server_ip': normalizedServerIp}),
    );

    final decoded = _decodeJson(response.body);
    final body = _asStringMap(decoded);

    if (response.statusCode != 200) {
      throw VpnException(
        _extractErrorMessage(body) ??
            (response.statusCode == 401
                ? 'Session expired. Please sign in again.'
                : 'Failed to provision VPN configuration.'),
      );
    }

    if (body == null) {
      throw const VpnException('Invalid VPN response from server.');
    }

    final serverConfig = _safeString(body['config']);
    final vlessLink = _safeString(body['vless_link']);
    final preferredConfig = vlessLink.isNotEmpty ? vlessLink : serverConfig;
    if (preferredConfig.isEmpty) {
      throw const VpnException('VPN configuration is missing in server response.');
    }

    final peer = _asStringMap(body['peer']);
    final clientConfig = _asStringMap(body['client_config']) ?? <String, dynamic>{};

    return VpnConnectResult(
      traceId: _safeString(body['trace_id'], fallback: traceId),
      connectAttempt: _safeInt(body['connect_attempt'], fallback: attempt),
      config: preferredConfig,
      serverConfig: serverConfig,
      vlessLink: vlessLink,
      clientConfig: clientConfig,
      assignedIp: _safeNullableString(peer?['assigned_ip']),
    );
  }

  static Future<void> applyProvisionedConfig(
    String configContent, {
    String? fallbackContent,
    String? preferredProfileName,
  }) async {
    final candidates = <String>[];

    void addCandidate(String? value) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty || candidates.contains(normalized)) {
        return;
      }
      candidates.add(normalized);
    }

    addCandidate(configContent);
    addCandidate(fallbackContent);

    CurrentAppBridgeException? bridgeError;
    Object? unexpectedError;

    for (final candidate in candidates) {
      try {
        await CurrentAppBridge.applyProvisionedConfig(candidate, preferredProfileName: preferredProfileName);
        return;
      } on CurrentAppBridgeException catch (error) {
        bridgeError = error;
      } catch (error) {
        unexpectedError = error;
      }
    }

    if (bridgeError != null) {
      throw VpnException(bridgeError.message);
    }
    if (unexpectedError != null) {
      throw VpnException('Failed to apply VPN configuration: $unexpectedError');
    }

    throw const VpnException('Failed to apply VPN configuration.');
  }

  static Future<List<ServerModel>> fetchVpnNodes() async {
    final response = await http.get(
      Uri.parse(AppConstants.vpnNodesEndpoint),
      headers: {'apikey': AppConstants.supabaseAnonKey, 'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}'},
    );

    if (response.statusCode != 200) {
      throw const VpnException('Failed to load VPN nodes');
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const VpnException('Invalid VPN nodes response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ServerModel.fromVpnNodeJson)
        .where((server) => server.publicIp.isNotEmpty)
        .toList(growable: false);
  }

  static Future<VpnMeteredUsage> fetchMeteredUsage({required String token}) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const VpnException('Please sign in to view usage.');
    }

    final response = await http.get(
      Uri.parse(AppConstants.getUsageEndpoint),
      headers: {'x-auth-token': 'Bearer $normalizedToken', 'apikey': AppConstants.supabaseAnonKey},
    );

    final decoded = _decodeJson(response.body);
    final body = _asStringMap(decoded);

    if (response.statusCode != 200 || body == null || body['success'] != true) {
      throw VpnException(
        _extractErrorMessage(body) ??
            (response.statusCode == 401 ? 'Session expired. Please sign in again.' : 'Failed to load VPN usage.'),
      );
    }

    final metered = _asStringMap(body['meteredUsage']);

    final usedBytes = _safeNonNegativeInt(metered?['used_bytes']);
    final allowedBytes = _safeNonNegativeInt(metered?['allowed_bytes']);
    final remainingBytes = _safeNonNegativeInt(metered?['remaining_bytes']);
    final planTier = _safeString(metered?['plan_tier'], fallback: 'free');

    final isPaidUserRaw = metered?['is_paid_user'];
    final isPaidUser = switch (isPaidUserRaw) {
      final bool value => value,
      final num value => value > 0,
      final String value => value.toLowerCase() == 'true' || value == '1',
      _ => false,
    };

    return VpnMeteredUsage(
      usedBytes: usedBytes,
      allowedBytes: allowedBytes,
      remainingBytes: remainingBytes,
      planTier: planTier,
      isPaidUser: isPaidUser,
    );
  }

  static Future<void> disconnect({String? traceId}) {
    return CurrentAppBridge.disconnect();
  }

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return null;
  }

  static String? _extractErrorMessage(Map<String, dynamic>? body) {
    final error = _safeNullableString(body?['error']);
    if (error != null && error.isNotEmpty) {
      return error;
    }

    final message = _safeNullableString(body?['message']);
    if (message != null && message.isNotEmpty) {
      return message;
    }

    return null;
  }

  static String _safeString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value.trim();
    }
    if (value == null) {
      return fallback;
    }
    return '$value'.trim();
  }

  static String? _safeNullableString(Object? value) {
    final normalized = _safeString(value);
    return normalized.isEmpty ? null : normalized;
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value > 0 ? value : fallback;
    }
    if (value is num) {
      final parsed = value.toInt();
      return parsed > 0 ? parsed : fallback;
    }
    final parsed = int.tryParse(_safeString(value));
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  static int _safeNonNegativeInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value >= 0 ? value : fallback;
    }
    if (value is num) {
      final parsed = value.toInt();
      return parsed >= 0 ? parsed : fallback;
    }

    final normalized = _safeString(value);
    if (normalized.isEmpty) {
      return fallback;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return fallback;
    }
    return parsed;
  }

  static Object? _decodeJson(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
      if (decoded is List) {
        return decoded
            .map((item) => item is Map ? item.map((k, v) => MapEntry('$k', v)) : item)
            .toList(growable: false);
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Stream<dynamic> get stageStream => const Stream<dynamic>.empty();

  static bool isPermissionDeniedError(Object error) => false;
}

class VpnException implements Exception {
  final String message;
  const VpnException(this.message);

  @override
  String toString() => message;
}

class VpnMeteredUsage {
  static const int _bytesPerGiB = 1024 * 1024 * 1024;

  final int usedBytes;
  final int allowedBytes;
  final int remainingBytes;
  final String planTier;
  final bool isPaidUser;

  const VpnMeteredUsage({
    required this.usedBytes,
    required this.allowedBytes,
    required this.remainingBytes,
    required this.planTier,
    required this.isPaidUser,
  });

  double get usedGiB => usedBytes / _bytesPerGiB;
  double get allowedGiB => allowedBytes / _bytesPerGiB;
  double get remainingGiB => remainingBytes / _bytesPerGiB;

  double get usageRatio {
    if (allowedBytes <= 0) {
      return 0;
    }
    final ratio = usedBytes / allowedBytes;
    return ratio.clamp(0.0, 1.0);
  }
}

class VpnPermissionRequiredException extends VpnException {
  const VpnPermissionRequiredException() : super('VPN permission is managed by the host app.');
}

class VpnConnectResult {
  final String traceId;
  final int connectAttempt;
  final String config;
  final String serverConfig;
  final String vlessLink;
  final Map<String, dynamic> clientConfig;
  final String? assignedIp;

  const VpnConnectResult({
    required this.traceId,
    required this.connectAttempt,
    required this.config,
    required this.serverConfig,
    required this.vlessLink,
    required this.clientConfig,
    required this.assignedIp,
  });
}
