import 'package:hiddify/ui_to_be/models/cloud_storage_file_model.dart';

class CloudStorageListResponse {
  final int quotaBytes;
  final int usedBytes;
  final List<CloudStorageFileModel> files;

  const CloudStorageListResponse({required this.quotaBytes, required this.usedBytes, required this.files});

  factory CloudStorageListResponse.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final fileItems = rawFiles is List ? rawFiles : const [];

    return CloudStorageListResponse(
      quotaBytes: _asInt(json['quotaBytes']),
      usedBytes: _asInt(json['usedBytes']),
      files: fileItems
          .whereType<Map>()
          .map((item) => CloudStorageFileModel.fromJson(item.map((key, value) => MapEntry('$key', value))))
          .toList(growable: false),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
