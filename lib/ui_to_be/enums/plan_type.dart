enum PlanType {
  standard,
  cloudGaming;

  String get label => switch (this) {
    PlanType.standard => 'VPS BASIC',
    PlanType.cloudGaming => 'CLOUD GAMING',
  };

  String get price => switch (this) {
    PlanType.standard => 'HK\$78',
    PlanType.cloudGaming => 'HK\$148',
  };

  /// Parse from DB tier string (e.g. 'standard', 'cloud_gaming').
  static PlanType? fromTier(String? tier) => switch (tier) {
    'standard' => PlanType.standard,
    'cloud_gaming' => PlanType.cloudGaming,
    'premium' => PlanType.cloudGaming,
    _ => null,
  };
}
