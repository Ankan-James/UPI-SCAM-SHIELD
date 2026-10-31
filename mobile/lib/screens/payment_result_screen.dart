import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/payment.dart';
import '../models/risk_assessment.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';
import '../widgets/risk_badge.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({required this.receipt, super.key});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final (label, description, color, icon) = switch (receipt.status) {
      PaymentStatus.success => (
          'Payment complete',
          'This simulated payment was recorded successfully.',
          AppColors.emerald,
          Icons.check_circle_rounded,
        ),
      PaymentStatus.pending => (
          'Payment pending',
          'The service has not confirmed the final payment status.',
          AppColors.amber,
          Icons.schedule_rounded,
        ),
      PaymentStatus.failed => (
          'Payment failed',
          'The service did not complete this simulated payment.',
          AppColors.red,
          Icons.cancel_rounded,
        ),
      PaymentStatus.blocked => (
          'Payment blocked',
          'NUMPE blocked this payment because the risk policy did not allow it.',
          AppColors.red,
          Icons.gpp_bad_rounded,
        ),
    };
    return NumpePage(
      title: 'Payment result',
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(icon, size: 64, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReceiptRow('Amount', '₹${receipt.amount.toStringAsFixed(2)}'),
                    _ReceiptRow('To', receipt.recipient),
                    _ReceiptRow('Reference', receipt.id),
                    _ReceiptRow(
                      'Date',
                      MaterialLocalizations.of(context)
                          .formatMediumDate(receipt.createdAt),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RiskBadge(level: receipt.risk.level),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'SIMULATED TRANSACTION · Not a bank receipt',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final indicator in receipt.risk.indicators)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('•  $indicator'),
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to home'),
            ),
            TextButton(
              onPressed: () => context.go('/activity'),
              child: const Text('View activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
