import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/payment.dart';
import '../services/scam_shield_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/numpe_page.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({this.initialDraft, super.key});

  final PaymentDraft? initialDraft;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipient;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _recipient = TextEditingController(text: draft?.recipient);
    _amount = TextEditingController(
      text: draft != null && draft.amount > 0
          ? draft.amount.toStringAsFixed(2)
          : '',
    );
    _note = TextEditingController(text: draft?.note);
  }

  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _reviewPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _checking = true);
    final draft = PaymentDraft(
      recipient: _recipient.text.trim(),
      amount: double.parse(_amount.text.trim()),
      note: _note.text.trim(),
    );
    try {
      final risk = await ScamShieldService().analyze(
        input: draft.recipient,
        type: 'upi_id',
        mode: SessionService.instance.mode,
      );
      if (mounted) {
        context.push(
          '/review',
          extra: PaymentReviewArgs(draft: draft, risk: risk),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Send money',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Who are you paying?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('Scam Shield checks the recipient before review.'),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _recipient,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Recipient UPI ID',
                  hintText: 'name@bank',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: Validators.upiId,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _checking ? null : _reviewPayment,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_outlined),
                label: Text(_checking ? 'Checking recipient…' : 'Review safely'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Demo payments are simulated and do not move real money.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
