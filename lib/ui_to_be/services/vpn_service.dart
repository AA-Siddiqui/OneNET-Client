import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';

class VpnService {
  // Kept for compatibility with older ui_to_be code paths.
  static Future<String> connect({
    required String token,
    required String serverIp,
    required String traceId,
    int attempt = 1,
  }) async {
    await CurrentAppBridge.connect();
    final active = await CurrentAppBridge.currentActiveServer();
    return active?.publicIp ?? '';
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

  static Future<void> disconnect({String? traceId}) {
    return CurrentAppBridge.disconnect();
  }

  static Object? _decodeJson(String payload) {
    try {
      final decoded = jsonDecode(payload);
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

class VpnPermissionRequiredException extends VpnException {
  const VpnPermissionRequiredException() : super('VPN permission is managed by the host app.');
}
