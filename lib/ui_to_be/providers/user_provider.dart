import 'package:flutter/foundation.dart';
import '../enums/plan_type.dart';
import '../enums/subscription_status.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  SubscriptionModel? _subscription;

  UserModel? get user => _user;
  SubscriptionModel? get subscription => _subscription;

  bool get isCloudGamingUser => _subscription?.planType == PlanType.cloudGaming;

  bool get isSubscriptionActive =>
      _subscription?.status == SubscriptionStatus.active || _subscription?.status == SubscriptionStatus.trialing;

  bool get hasActivePlan => _subscription != null && isSubscriptionActive;

  String get planLabel => _subscription?.planType.label ?? 'NO PLAN';

  /// Load user and subscription from the raw login response JSON.
  void loadFromLoginData(Map<String, dynamic> loginData) {
    final userData = loginData['user'] as Map<String, dynamic>?;
    final subData = loginData['subscription'] as Map<String, dynamic>?;

    if (userData != null) {
      _user = UserModel.fromJson(userData);
    }

    if (subData != null) {
      _subscription = SubscriptionModel.fromJson(subData);
    } else {
      _subscription = null;
    }

    notifyListeners();
  }

  void clear() {
    _user = null;
    _subscription = null;
    notifyListeners();
  }
}
