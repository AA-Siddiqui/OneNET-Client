import 'dart:convert';

import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _firstTimeGamingKey = 'first_time_gaming';
  static const _lastSelectedVpnServerKey = 'last_selected_vpn_server';
  static const _vpnConnectedSinceKey = 'vpn_connected_since';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isFirstTimeGaming() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeGamingKey) ?? true;
  }

  static Future<void> setFirstTimeGamingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeGamingKey, false);
  }

  static Future<void> saveLastSelectedVpnServer(ServerModel server) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastSelectedVpnServerKey,
      jsonEncode({
        'id': server.id,
        'name': server.name,
        'region': server.region,
        'nodeId': server.nodeId,
        'publicIp': server.publicIp,
        'isAvailable': server.isAvailable,
      }),
    );
  }

  static Future<ServerModel?> getLastSelectedVpnServer() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_lastSelectedVpnServerKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return null;
      }

      final map = decoded.map((key, value) => MapEntry('$key', value));
      final id = _stringOrEmpty(map['id']);
      final name = _stringOrEmpty(map['name']);
      final publicIp = _stringOrEmpty(map['publicIp']);

      if (id.isEmpty && name.isEmpty && publicIp.isEmpty) {
        return null;
      }

      return ServerModel(
        id: id,
        name: name,
        region: _stringOrEmpty(map['region']),
        nodeId: _stringOrEmpty(map['nodeId']),
        publicIp: publicIp,
        isAvailable: map['isAvailable'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveVpnConnectedSince(DateTime connectedSince) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vpnConnectedSinceKey, connectedSince.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getVpnConnectedSince() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_vpnConnectedSinceKey);
    if (raw == null || raw <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  static Future<void> clearVpnConnectedSince() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vpnConnectedSinceKey);
  }

  static String _stringOrEmpty(Object? value) {
    if (value is String) {
      return value.trim();
    }
    if (value == null) {
      return '';
    }
    return '$value'.trim();
  }
}
