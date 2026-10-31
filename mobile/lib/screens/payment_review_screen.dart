import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/payment.dart';
import '../models/risk_assessment.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';
import '../widgets/risk_badge.dart';

class PaymentReviewScreen extends StatefulWidget {
  const PaymentReviewScreen({required this.arguments, super.key});

  final PaymentReviewArgs arguments;

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final receipt = await PaymentService().submit(
        widget.arguments.draft,
        risk: widget.arguments.risk,
        mode: SessionService.instance.mode,
      );
      if (mounted) context.go('/payment-result', extra: receipt);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.arguments.draft;
    final risk = widget.arguments.risk;
    final highRisk = risk.level == RiskLevel.high;
    return NumpePage(
      title: 'Review payment',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Check before you send',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PAYING'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(draft.recipient,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    Text('₹${draft.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (draft.note.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text('Note: ${draft.note}'),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Recipient identity is not independently verified.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Scam Shield',
                            style: Theme.of(context).textTheme.titleMedium),
                        RiskBadge(level: risk.level),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Risk score ${risk.score}/100'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(risk.explanation),
                    const SizedBox(height: AppSpacing.sm),
                    for (final indicator in risk.indicators)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(indicator)),
                          ],
                        ),
                      ),
                    Text(
                      risk.recommendation,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'This is an estimate, not proof of fraud.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (highRisk)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'This high-risk payment is blocked by NUMPE’s safety policy. '
                    'You can cancel and verify the recipient independently.',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              FilledButton(
                onPressed: _submitting ? null : _confirm,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm simulated payment'),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _submitting ? null : () => context.go('/home'),
              child: Text(highRisk ? 'Done' : 'Cancel payment'),
            ),
          ],
        ),
      ),
    );
  }
}
