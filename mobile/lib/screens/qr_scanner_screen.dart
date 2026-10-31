import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/payment.dart';
import '../services/qr_service.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _manual = TextEditingController();
  final _scanner = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _qr = QrService();
  PaymentDraft? _draft;
  String? _error;
  String? _otherPayload;
  bool _handled = false;

  @override
  void dispose() {
    _manual.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _handled = true;
        _inspect(value);
        return;
      }
    }
  }

  void _inspect(String value) {
    final trimmed = value.trim();
    final payment = _qr.parsePaymentPayload(trimmed);
    setState(() {
      _error = null;
      _draft = payment;
      _otherPayload = null;
      if (payment == null && trimmed.toLowerCase().startsWith('upi:')) {
        _error = 'This payment QR is malformed or has an unsupported payload.';
      } else if (payment == null) {
        _otherPayload = trimmed;
      }
    });
  }

  void _manualInspect() {
    if (_manual.text.trim().isEmpty) {
      setState(() => _error = 'Paste a QR payload to inspect.');
      return;
    }
    _handled = true;
    _inspect(_manual.text);
  }

  void _useRecipient() {
    final draft = _draft;
    if (draft == null) return;
    context.push('/send', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Scan QR',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Scan a payment QR',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'NUMPE only reads the code. Review and check the recipient before '
            'any simulated payment.',
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 280,
              child: MobileScanner(
                controller: _scanner,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) => Container(
                  color: AppColors.navy,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Camera unavailable. Allow camera access or paste a test '
                    'payload below.\n${error.errorCode.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Test payment QR payload: upi://pay?pa=merchant@bank&pn=Merchant&am=25.00&cu=INR',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _manual,
            decoration: InputDecoration(
              labelText: 'Paste QR payload',
              suffixIcon: IconButton(
                tooltip: 'Inspect payload',
                onPressed: _manualInspect,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            onSubmitted: (_) => _manualInspect(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          if (_draft != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Payment details found',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('Recipient: ${_draft!.recipient}'),
                    if (_draft!.amount > 0)
                      Text('Amount: ₹${_draft!.amount.toStringAsFixed(2)}')
                    else
                      const Text('Amount: enter it on the next screen.'),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _useRecipient,
                      child: const Text('Check recipient & continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_otherPayload != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'This is not a supported payment QR. You can check its '
                      'text or link with Scam Shield.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () =>
                          context.push('/analyze', extra: _otherPayload),
                      child: const Text('Analyze with Scam Shield'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}