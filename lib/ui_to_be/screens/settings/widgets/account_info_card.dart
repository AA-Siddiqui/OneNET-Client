import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../enums/subscription_status.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/glow_container.dart';
import '../../../widgets/common/status_badge.dart';

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        final subscription = user.subscription;
        final statusBadge = switch (subscription?.status) {
          SubscriptionStatus.active => StatusBadge.active(),
          SubscriptionStatus.trialing => StatusBadge.trialing(),
          SubscriptionStatus.expired => StatusBadge.expired(),
          SubscriptionStatus.pending => StatusBadge.pending(),
          SubscriptionStatus.cancelled => StatusBadge.expired(),
          null => const StatusBadge(label: '---', color: AppColors.textDim),
        };

        return GlowContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User info row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGlow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.accentBright, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.user?.email ?? '---',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBright),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge.plan(user.planLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
              // Details rows
              _DetailRow(label: 'STATUS', child: statusBadge),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'PLAN',
                child: Text(
                  subscription != null
                      ? '${subscription.planType.label} · ${Formatters.price(subscription.priceHkd)}/mo'
                      : '---',
                  style: AppTextStyles.mono.copyWith(color: AppColors.textBright, fontSize: 11),
                ),
              ),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'RENEWAL',
                child: Text(
                  subscription != null ? Formatters.date(subscription.renewalDate) : '---',
                  style: AppTextStyles.mono.copyWith(color: AppColors.accent, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
        ),
        Expanded(child: child),
      ],
    );
  }
}
