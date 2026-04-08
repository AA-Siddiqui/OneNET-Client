enum SubscriptionStatus {
  active,
  trialing,
  expired,
  pending,
  cancelled;

  String get label => switch (this) {
    SubscriptionStatus.active => 'ACTIVE',
    SubscriptionStatus.trialing => 'TRIALING',
    SubscriptionStatus.expired => 'EXPIRED',
    SubscriptionStatus.pending => 'PENDING',
    SubscriptionStatus.cancelled => 'CANCELLED',
  };

  static SubscriptionStatus fromString(String value) => switch (value) {
    'active' => SubscriptionStatus.active,
    'trialing' => SubscriptionStatus.trialing,
    'expired' => SubscriptionStatus.expired,
    'pending' => SubscriptionStatus.pending,
    'cancelled' => SubscriptionStatus.cancelled,
    _ => SubscriptionStatus.expired,
  };
}
