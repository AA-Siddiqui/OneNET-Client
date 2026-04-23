class AppRelease {
  final String version;
  final DateTime releaseDate;
  final DateTime? lastUsableDate;
  final String? downloadUrl;
  final String? notes;

  AppRelease({required this.version, required this.releaseDate, this.lastUsableDate, this.downloadUrl, this.notes});

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      if (v is DateTime) return v.toUtc();
      return null;
    }

    return AppRelease(
      version: json['version'] as String? ?? '',
      releaseDate: parseDate(json['release_date']) ?? DateTime.now().toUtc(),
      lastUsableDate: parseDate(json['last_usable_date']),
      downloadUrl: json['download_url'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
