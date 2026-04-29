import 'dart:convert';

import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_access_model.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_list_response.dart';
import 'package:http/http.dart' as http;

class DownloadedCloudFile {
  final List<int> bytes;
  final String contentType;
  final String fileName;

  const DownloadedCloudFile({required this.bytes, required this.contentType, required this.fileName});
}

class CloudStorageUploadFile {
  final String fileName;
  final List<int> bytes;

  const CloudStorageUploadFile({required this.fileName, required this.bytes});
}

class CloudShareLink {
  final String url;
  final String? email;

  const CloudShareLink({required this.url, this.email});
}

class CloudShareResult {
  final String token;
  final String mode;
  final String? shareUrl;
  final DateTime? expiresAt;
  final List<CloudShareLink> shareLinks;

  const CloudShareResult({
    required this.token,
    required this.mode,
    required this.shareUrl,
    required this.expiresAt,
    required this.shareLinks,
  });

  bool get isEmailRestricted => mode == 'email';
}

class CloudStorageService {
  static Map<String, String> _supabaseHeaders(String token) => {
    'x-auth-token': 'Bearer $token',
    'apikey': AppConstants.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
  };

  static Map<String, String> _jsonHeaders(String token) => {
    ..._supabaseHeaders(token),
    'Content-Type': 'application/json',
  };

  static Uri _gatewayUri(String action, [Map<String, String?> query = const {}]) {
    final normalizedQuery = <String, String>{'action': action};

    query.forEach((key, value) {
      if (value == null) {
        return;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      normalizedQuery[key] = trimmed;
    });

    return Uri.parse(AppConstants.storageGatewayEndpoint).replace(queryParameters: normalizedQuery);
  }

  static Future<CloudStorageAccessModel> fetchAccess(String token) async {
    final response = await http.get(_gatewayUri('access'), headers: _supabaseHeaders(token));

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Failed to check cloud storage access');
    }

    return CloudStorageAccessModel.fromSupabase(body);
  }

  static Future<CloudStorageListResponse> fetchFiles(String token, {String path = ''}) async {
    final response = await http.get(_gatewayUri('files', {'path': path}), headers: _supabaseHeaders(token));

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

  static Future<void> uploadFile({
    required String token,
    required String fileName,
    required List<int> bytes,
    String path = '',
  }) async {
    await uploadFiles(
      token: token,
      files: [CloudStorageUploadFile(fileName: fileName, bytes: bytes)],
      path: path,
    );
  }

  static Future<void> uploadFiles({
    required String token,
    required List<CloudStorageUploadFile> files,
    String path = '',
  }) async {
    if (files.isEmpty) {
      throw const CloudStorageException('No files selected for upload.');
    }

    final request = http.MultipartRequest('POST', _gatewayUri('upload', {'path': path}));
    request.headers.addAll(_supabaseHeaders(token));
    if (path.trim().isNotEmpty) {
      request.fields['path'] = path;
    }
    for (final file in files) {
      request.files.add(http.MultipartFile.fromBytes('file', file.bytes, filename: file.fileName));
    }

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

  static Future<CloudShareResult> createShareLink({
    required String token,
    required String itemType,
    required String path,
    required bool isPublic,
    List<String> emails = const [],
  }) async {
    final response = await http.post(
      _gatewayUri('share-create'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'itemType': itemType,
        'path': path,
        'mode': isPublic ? 'public' : 'email',
        if (!isPublic) 'emails': emails,
      }),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Failed to create share link');
    }

    final links = <CloudShareLink>[];
    if (body['share_links'] is List) {
      for (final entry in body['share_links'] as List) {
        if (entry is Map) {
          final url = entry['url'] as String?;
          if (url != null && url.trim().isNotEmpty) {
            links.add(CloudShareLink(url: url, email: entry['email'] as String?));
          }
        }
      }
    }

    final expiresAtRaw = body['expires_at'] as String?;
    final expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;

    return CloudShareResult(
      token: body['token'] as String? ?? '',
      mode: body['mode'] as String? ?? (isPublic ? 'public' : 'email'),
      shareUrl: body['share_url'] as String?,
      expiresAt: expiresAt,
      shareLinks: links,
    );
  }

  static Future<DownloadedCloudFile> downloadFile({required String token, required String fileKey}) async {
    final response = await http.get(_gatewayUri('download', {'key': fileKey}), headers: _supabaseHeaders(token));

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
      fileName:
          _extractFileNameFromContentDisposition(response.headers['content-disposition']) ?? _nameFromPath(fileKey),
    );
  }

  static Future<DownloadedCloudFile> downloadFolderAsZip({required String token, required String folderPath}) async {
    final response = await http.get(
      _gatewayUri('download-folder', {'path': folderPath}),
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
      throw CloudStorageException(body?['error'] as String? ?? 'Folder download failed');
    }

    final folderName = _nameFromPath(folderPath);
    return DownloadedCloudFile(
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? 'application/zip',
      fileName: _extractFileNameFromContentDisposition(response.headers['content-disposition']) ?? '$folderName.zip',
    );
  }

  static Future<void> deleteFile({required String token, required String fileKey}) async {
    final response = await http.delete(_gatewayUri('delete', {'key': fileKey}), headers: _supabaseHeaders(token));

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Delete failed');
    }
  }

  static Future<void> createFolder({required String token, required String path}) async {
    final response = await http.post(
      _gatewayUri('create-folder'),
      headers: _jsonHeaders(token),
      body: jsonEncode({'path': path}),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Create folder failed');
    }
  }

  static Future<void> deleteFolder({required String token, required String path}) async {
    final response = await http.delete(_gatewayUri('delete-folder', {'path': path}), headers: _supabaseHeaders(token));

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Delete folder failed');
    }
  }

  static Future<void> copyItem({
    required String token,
    required String itemType,
    required String sourcePath,
    required String destinationPath,
    String? newName,
  }) async {
    final response = await http.post(
      _gatewayUri('copy'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'itemType': itemType,
        'sourcePath': sourcePath,
        'destinationPath': destinationPath,
        if (newName != null && newName.trim().isNotEmpty) 'newName': newName.trim(),
      }),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Copy failed');
    }
  }

  static Future<void> moveItem({
    required String token,
    required String itemType,
    required String sourcePath,
    required String destinationPath,
    String? newName,
  }) async {
    final response = await http.post(
      _gatewayUri('move'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'itemType': itemType,
        'sourcePath': sourcePath,
        'destinationPath': destinationPath,
        if (newName != null && newName.trim().isNotEmpty) 'newName': newName.trim(),
      }),
    );

    final body = _decodeBody(response);

    if (response.statusCode == 401) {
      throw const CloudStorageException('Session expired. Please sign in again.');
    }

    if (response.statusCode >= 400 || body['success'] != true) {
      throw CloudStorageException(body['error'] as String? ?? 'Move failed');
    }
  }

  static String? _extractFileNameFromContentDisposition(String? headerValue) {
    final value = headerValue?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final utf8Match = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(value);
    if (utf8Match != null) {
      final encoded = utf8Match.group(1);
      if (encoded != null && encoded.isNotEmpty) {
        return Uri.decodeComponent(encoded);
      }
    }

    final plainMatch = RegExp('filename="?([^";]+)"?', caseSensitive: false).firstMatch(value);
    if (plainMatch != null) {
      final plain = plainMatch.group(1)?.trim();
      if (plain != null && plain.isNotEmpty) {
        return plain;
      }
    }

    return null;
  }

  static String _nameFromPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return 'download';
    }

    final segments = trimmed.split('/').where((segment) => segment.trim().isNotEmpty).toList(growable: false);
    if (segments.isEmpty) {
      return 'download';
    }

    return segments.last;
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
