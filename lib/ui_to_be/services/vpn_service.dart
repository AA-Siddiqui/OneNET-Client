import 'package:hiddify/ui_to_be/models/server_model.dart';
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

  static Future<List<ServerModel>> fetchVpnNodes() {
    return CurrentAppBridge.fetchServers();
  }

  static Future<void> disconnect({String? traceId}) {
    return CurrentAppBridge.disconnect();
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
