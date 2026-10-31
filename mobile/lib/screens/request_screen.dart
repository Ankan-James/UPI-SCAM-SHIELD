import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/mock_data_service.dart';
import '../services/qr_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/numpe_page.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _payload;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _createRequest() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _payload = QrService().createPaymentPayload(
        upiId: MockDataService.demoUpiId,
        name: 'Disha Naskar',
        amount: double.parse(_amount.text),
        note: _note.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Request money',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create a demo request',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Generate a simulated payment QR to show the amount requested. '
                'This does not send a request to another person.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              FilledButton(
                onPressed: _createRequest,
                child: const Text('Generate simulated request'),
              ),
              if (_payload != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Text(
                          'Request for ₹${double.parse(_amount.text).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_note.text.trim().isNotEmpty)
                          Text(_note.text.trim()),
                        const SizedBox(height: AppSpacing.md),
                        QrImageView(
                          data: _payload!,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                        const Text(
                          'DEMO QR · Not a real payment request',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
