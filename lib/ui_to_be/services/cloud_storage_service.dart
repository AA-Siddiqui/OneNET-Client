import 'dart:convert';

import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_access_model.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_list_response.dart';
import 'package:http/http.dart' as http;

class DownloadedCloudFile {
  final List<int> bytes;
  final String contentType;

  const DownloadedCloudFile({required this.bytes, required this.contentType});
}

class CloudStorageService {
  static Map<String, String> _supabaseHeaders(String token) => {
    'x-auth-token': 'Bearer $token',
    'apikey': AppConstants.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
  };

  static Future<CloudStorageAccessModel> fetchAccess(String token) async {
    final response = await http.get(
      Uri.parse('${AppConstants.storageGatewayEndpoint}?action=access'),
      headers: _supabaseHeaders(token),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Failed to check cloud storage access');
    }

    return CloudStorageAccessModel.fromSupabase(body);
  }

  static Future<CloudStorageListResponse> fetchFiles(String token) async {
    final response = await http.get(
      Uri.parse('${AppConstants.storageGatewayEndpoint}?action=files'),
      headers: _supabaseHeaders(token),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode == 403) {
      throw CloudStorageException(body['error'] as String? ?? 'Pro plan is required for cloud storage');
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Failed to load cloud storage files');
    }

    return CloudStorageListResponse.fromJson(body);
  }

  static Future<void> uploadFile({required String token, required String fileName, required List<int> bytes}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.storageGatewayEndpoint}?action=upload'));
    request.headers.addAll(_supabaseHeaders(token));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode == 403) {
      throw CloudStorageException(body['error'] as String? ?? 'Upload denied by plan limits');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Upload failed');
    }
  }

  static Future<DownloadedCloudFile> downloadFile({required String token, required String fileKey}) async {
    final response = await http.get(
      Uri.parse('${AppConstants.storageGatewayEndpoint}?action=download&key=${Uri.encodeQueryComponent(fileKey)}'),
      headers: _supabaseHeaders(token),
    );

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = null;
      }
      throw CloudStorageException(body?['error'] as String? ?? 'Download failed');
    }

    return DownloadedCloudFile(
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? 'application/octet-stream',
    );
  }

  static Future<void> deleteFile({required String token, required String fileKey}) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.storageGatewayEndpoint}?action=delete&key=${Uri.encodeQueryComponent(fileKey)}'),
      headers: _supabaseHeaders(token),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Delete failed');
    }
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

class CloudStorageException implements Exception {
  final String message;

  const CloudStorageException(this.message);

  @override
  String toString() => message;
}
