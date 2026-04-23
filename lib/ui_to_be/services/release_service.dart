import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/models/release.dart';

class ReleaseService {
  /// Fetch latest release row from Supabase REST API (ordered by release_date desc)
  static Future<AppRelease?> fetchLatestRelease() async {
    final uri = Uri.parse(
      '${AppConstants.supabaseUrl}/rest/v1/app_releases?select=version,release_date,last_usable_date,download_url,notes&order=release_date.desc&limit=1',
    );
    try {
      final response = await http.get(
        uri,
        headers: {'apikey': AppConstants.supabaseAnonKey, 'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as List<dynamic>;
      if (body.isEmpty) return null;
      final map = body.first as Map<String, dynamic>;
      return AppRelease.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
