class CloudStorageFileModel {
  final String key;
  final String name;
  final bool isFolder;
  final int sizeBytes;
  final DateTime? lastModified;

  const CloudStorageFileModel({
    required this.key,
    required this.name,
    required this.isFolder,
    required this.sizeBytes,
    required this.lastModified,
  });

  factory CloudStorageFileModel.fromJson(Map<String, dynamic> json) {
    final lastModifiedRaw = json['lastModified'] as String?;
    final kind = (json['kind'] ?? json['type']) as String?;
    final normalizedKind = kind?.trim().toLowerCase();
    final isFolder = normalizedKind == 'folder' || json['isFolder'] == true;

    return CloudStorageFileModel(
      key: (json['key'] ?? json['path']) as String? ?? '',
      name: json['name'] as String? ?? (isFolder ? 'folder' : 'file'),
      isFolder: isFolder,
      sizeBytes: _asInt(json['sizeBytes']),
      lastModified: lastModifiedRaw == null ? null : DateTime.tryParse(lastModifiedRaw),
    );
  }

  bool get isFile => !isFolder;

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
