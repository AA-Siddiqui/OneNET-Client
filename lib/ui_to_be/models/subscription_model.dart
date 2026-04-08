import '../enums/plan_type.dart';
import '../enums/subscription_status.dart';

class SubscriptionModel {
  final PlanType planType;
  final SubscriptionStatus status;
  final DateTime renewalDate;
  final double priceHkd;
  final String? planName;
  final String? maxResolution;
  final int? maxFps;
  final int? dailyHours;

  const SubscriptionModel({
    required this.planType,
    required this.status,
    required this.renewalDate,
    required this.priceHkd,
    this.planName,
    this.maxResolution,
    this.maxFps,
    this.dailyHours,
  });

  /// Parse from the `subscription` object in the login response.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;
    final periodEnd = json['current_period_end'] as String?;

    return SubscriptionModel(
      planType: PlanType.fromTier(plan?['tier'] as String?) ?? PlanType.standard,
      status: SubscriptionStatus.fromString(json['status'] as String? ?? ''),
      renewalDate: periodEnd != null ? DateTime.parse(periodEnd) : DateTime.now().add(const Duration(days: 30)),
      priceHkd: (plan?['price_hkd'] as num?)?.toDouble() ?? 0,
      planName: plan?['name'] as String?,
      maxResolution: plan?['max_resolution'] as String?,
      maxFps: plan?['max_fps'] as int?,
      dailyHours: plan?['daily_hours'] as int?,
    );
  }
}
