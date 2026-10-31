import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/loading_indicator.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({this.initialType, super.key});

  final String? initialType;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _input = TextEditingController();
  final _api = ApiService();
  late String _type;
  bool _loading = false;
  String? _error;

  static const _types = {
    'text': 'Message or payment request',
    'url': 'Website link',
    'recipient': 'UPI ID or recipient',
    'qr': 'QR code contents',
    'screenshot': 'Text copied from a screenshot',
  };

  @override
  void initState() {
    super.initState();
    _type =
        _types.containsKey(widget.initialType) ? widget.initialType! : 'text';
  }

  @override
  void dispose() {
    _input.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ScanResult result = await _api.analyze(_type, _input.text.trim());
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Check for a scam')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('What would you like to check?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Check type'),
              items: _types.entries
                  .map((item) => DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _input,
                minLines: 5,
                maxLines: 10,
                maxLength: 14000000,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Paste the message, link, or UPI ID',
                  hintText: 'Do not include your PIN, OTP, or password.',
                ),
                validator: (value) => requiredInput(value, label: 'Content'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Analyze safely'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analysis is a guide, not a guarantee. Never send money based only on a scan result.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
