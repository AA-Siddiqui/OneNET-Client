import '../enums/plan_type.dart';
import '../enums/subscription_status.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../models/server_model.dart';

sealed class MockData {
  // Cloud Gaming user — sees all features
  static final UserModel cloudGamingUser = UserModel(
    id: 'usr_001',
    email: 'gamer@example.com',
    username: 'gamer01',
    displayName: 'Gamer One',
  );

  static final SubscriptionModel cloudGamingSubscription = SubscriptionModel(
    planType: PlanType.cloudGaming,
    status: SubscriptionStatus.active,
    renewalDate: DateTime(2026, 4, 12),
    priceHkd: 148.0,
  );

  // VPS Basic user — no cloud gaming
  static final UserModel vpsUser = UserModel(
    id: 'usr_002',
    email: 'vpnuser@example.com',
    username: 'vpnuser02',
    displayName: 'VPN User',
  );

  static final SubscriptionModel vpsSubscription = SubscriptionModel(
    planType: PlanType.standard,
    status: SubscriptionStatus.active,
    renewalDate: DateTime(2026, 4, 5),
    priceHkd: 78.0,
  );

  // Expired user
  static final SubscriptionModel expiredSubscription = SubscriptionModel(
    planType: PlanType.standard,
    status: SubscriptionStatus.expired,
    renewalDate: DateTime(2026, 3, 1),
    priceHkd: 78.0,
  );

  static final ServerModel server = ServerModel.malaysia();

  static const String mockIp = '103.123.45.67';
}
