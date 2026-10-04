import 'dart:convert';

import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _tokenSavedAtKey = 'auth_token_saved_at';
  static const _loginDataKey = 'auth_login_data';
  static const _firstTimeGamingKey = 'first_time_gaming';
  static const _lastSelectedVpnServerKey = 'last_selected_vpn_server';
  static const _vpnConnectedSinceKey = 'vpn_connected_since';
  static const _topDownSpeedKey = 'top_download_speed';
  static const _topUpSpeedKey = 'top_upload_speed';
  static const _tokenMaxAge = Duration(days: 365);

  static Future<void> saveTopDownloadSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_topDownSpeedKey, speed);
  }

  static Future<double?> getTopDownloadSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_topDownSpeedKey);
  }

  static Future<void> saveTopUploadSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_topUpSpeedKey, speed);
  }

  static Future<double?> getTopUploadSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_topUpSpeedKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_tokenSavedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final savedAtRaw = prefs.getInt(_tokenSavedAtKey);
    if (savedAtRaw == null) {
      await prefs.setInt(
        _tokenSavedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return token;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtRaw);
    if (DateTime.now().difference(savedAt) > _tokenMaxAge) {
      await clearToken();
      return null;
    }

    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenSavedAtKey);
    await prefs.remove(_loginDataKey);
  }

  static Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginDataKey, jsonEncode(loginData));
  }

  static Future<Map<String, dynamic>?> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_loginDataKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return null;
      }
      return decoded.map((key, value) => MapEntry('$key', value));
    } catch (_) {
      return null;
    }
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
    await prefs.setInt(
      _vpnConnectedSinceKey,
      connectedSince.millisecondsSinceEpoch,
    );
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
