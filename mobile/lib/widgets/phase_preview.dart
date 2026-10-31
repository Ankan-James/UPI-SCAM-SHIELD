import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PhasePreview extends StatelessWidget {
  const PhasePreview({
    required this.title,
    required this.description,
    required this.icon,
    this.isHome = false,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHome ? 'Smart Payments. Safer Transactions.' : title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isHome
                    ? 'A simulated UPI-style experience with safety built in.'
                    : description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x174361EE),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: AppColors.blue),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHome ? 'Welcome to NUMPE' : title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              isHome
                                  ? 'Your payment dashboard is being prepared. '
                                      'Balance, transfers and QR tools will be '
                                      'added in the next implementation phases.'
                                  : '$description This feature is coming soon.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (!isHome) ...[
                              const SizedBox(height: AppSpacing.md),
                              const _ComingSoonLabel(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isHome) ...[
                const SizedBox(height: AppSpacing.md),
                const _SimulationNotice(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonLabel extends StatelessWidget {
  const _ComingSoonLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'COMING SOON',
          style: TextStyle(
            color: Color(0xFF9A5B00),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.blue, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'NUMPE is a demo. It does not connect to banks or real UPI '
              'networks. Balances and payments will be simulated.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
