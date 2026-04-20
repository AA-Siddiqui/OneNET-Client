class CloudStorageFileModel {
  final String key;
  final String name;
  final int sizeBytes;
  final DateTime? lastModified;

  const CloudStorageFileModel({
    required this.key,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
  });

  factory CloudStorageFileModel.fromJson(Map<String, dynamic> json) {
    final lastModifiedRaw = json['lastModified'] as String?;

    return CloudStorageFileModel(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? 'file',
      sizeBytes: _asInt(json['sizeBytes']),
      lastModified: lastModifiedRaw == null ? null : DateTime.tryParse(lastModifiedRaw),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
