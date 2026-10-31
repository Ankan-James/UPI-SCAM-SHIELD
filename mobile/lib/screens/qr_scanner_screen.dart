import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';
import 'result_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _processing = false;
  String? _error;
  final _api = ApiService();

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    String? value;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        value = barcode.rawValue;
        break;
      }
    }
    if (value == null || value.isEmpty) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final ScanResult result = await _api.analyze('qr', value);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(result: result),
        ),
      );
      if (mounted) setState(() => _processing = false);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan a QR code')),
        body: _processing
            ? const LoadingIndicator(label: 'Checking QR code...')
            : Column(
                children: [
                  Expanded(
                    child: MobileScanner(
                      onDetect: _onDetect,
                      errorBuilder: (context, error, child) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Camera unavailable. Check camera permission and try again.\n${error.errorCode.name}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Keep the code in the frame. Never approve a payment or enter your UPI PIN just to receive money.',
                          textAlign: TextAlign.center,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      );
}
