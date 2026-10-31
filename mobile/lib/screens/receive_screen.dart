import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/mock_data_service.dart';
import '../services/qr_service.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payload = QrService().createPaymentPayload(
      upiId: MockDataService.demoUpiId,
      name: 'Disha Naskar',
    );
    return NumpePage(
      title: 'Receive money',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text('Your personal QR',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Share this simulated QR with someone to show how receiving '
              'could work. It will not move real money.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0x1A4361EE),
                      child: Icon(Icons.person, color: AppColors.blue, size: 30),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Disha Naskar',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      MockDataService.demoUpiId,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QrImageView(
                      data: payload,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'SIMULATED RECEIVING QR',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
