class CloudStorageAccessModel {
  final bool hasStorageAccess;
  final bool isPro;
  final int quotaBytes;
  final int usedBytes;
  final String message;
  final String? planTier;
  final String? planName;
  final String? subscriptionStatus;

  const CloudStorageAccessModel({
    required this.hasStorageAccess,
    required this.isPro,
    required this.quotaBytes,
    required this.usedBytes,
    required this.message,
    this.planTier,
    this.planName,
    this.subscriptionStatus,
  });

  factory CloudStorageAccessModel.fromSupabase(Map<String, dynamic> json) {
    final hasAccess = (json['has_storage_access'] == true) || (json['hasStorageAccess'] == true);
    final quota = _asInt(json['quota_bytes'] ?? json['quotaBytes']);
    final used = _asInt(json['used_bytes'] ?? json['usedBytes']);

    return CloudStorageAccessModel(
      hasStorageAccess: hasAccess,
      isPro: json['is_pro'] == true || hasAccess,
      quotaBytes: quota,
      usedBytes: used,
      message: json['message'] as String? ?? 'Pro plan is required for cloud storage',
      planTier: (json['plan_tier'] ?? json['planTier']) as String?,
      planName: (json['plan_name'] ?? json['planName']) as String?,
      subscriptionStatus: (json['subscription_status'] ?? json['subscriptionStatus']) as String?,
    );
  }

  CloudStorageAccessModel copyWith({
    bool? hasStorageAccess,
    bool? isPro,
    int? quotaBytes,
    int? usedBytes,
    String? message,
    String? planTier,
    String? planName,
    String? subscriptionStatus,
  }) {
    return CloudStorageAccessModel(
      hasStorageAccess: hasStorageAccess ?? this.hasStorageAccess,
      isPro: isPro ?? this.isPro,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      message: message ?? this.message,
      planTier: planTier ?? this.planTier,
      planName: planName ?? this.planName,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }

  double get usageRatio {
    if (quotaBytes <= 0) {
      return 0;
    }

    final ratio = usedBytes / quotaBytes;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }

  int get remainingBytes {
    final remaining = quotaBytes - usedBytes;
    return remaining < 0 ? 0 : remaining;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
