import 'package:flutter/material.dart';

<<<<<<< HEAD
import '../config/api_config.dart';
import '../models/risk_assessment.dart';
import '../services/api_service.dart';
import '../services/qr_service.dart';
import '../services/scam_shield_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';
import '../widgets/risk_badge.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({this.initialInput, super.key});

  final String? initialInput;
=======
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/loading_indicator.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({this.initialType, super.key});

  final String? initialType;
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
<<<<<<< HEAD
  late final TextEditingController _input;
  String _type = 'text';
  bool _loading = false;
  String? _error;
  RiskAssessment? _result;
=======
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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _input = TextEditingController(text: widget.initialInput);
    if (widget.initialInput != null) {
      final uri = Uri.tryParse(widget.initialInput!);
      _type = uri?.hasScheme == true ? 'url' : 'text';
    }
=======
    _type =
        _types.containsKey(widget.initialType) ? widget.initialType! : 'text';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
  }

  @override
  void dispose() {
    _input.dispose();
<<<<<<< HEAD
=======
    _api.close();
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
    super.dispose();
  }

  Future<void> _analyze() async {
<<<<<<< HEAD
    final value = _input.text.trim();
    if (value.isEmpty) {
      setState(() {
        _error = 'Enter a message, URL, recipient ID or supported QR payload.';
        _result = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    var analyzeValue = value;
    var analyzeType = _type;
    if (_type == 'qr') {
      final draft = QrService().parsePaymentPayload(value);
      if (draft != null) {
        analyzeValue = draft.recipient;
        analyzeType = 'upi_id';
      } else if (value.toLowerCase().startsWith('upi:')) {
        setState(() {
          _loading = false;
          _error = 'This QR payload is malformed or unsupported.';
        });
        return;
      } else {
        final uri = Uri.tryParse(value);
        analyzeType = uri?.hasScheme == true ? 'url' : 'text';
      }
    }

    try {
      final result = await ScamShieldService().analyze(
        input: analyzeValue,
        type: analyzeType,
        mode: SessionService.instance.mode,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
=======
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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return NumpePage(
      title: 'Scam Shield',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Check before you trust',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Review a message, URL, UPI ID or supported payment QR. '
              'An estimate is not proof of fraud.',
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'What are you checking?'),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Message or text')),
                DropdownMenuItem(value: 'url', child: Text('Website link')),
                DropdownMenuItem(value: 'upi_id', child: Text('Recipient UPI ID')),
                DropdownMenuItem(value: 'qr', child: Text('QR payload')),
              ],
              onChanged: (value) => setState(() {
                _type = value ?? 'text';
                _result = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _input,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Paste content to check',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(_loading ? 'Checking…' : 'Analyze safely'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
              if (SessionService.instance.mode == AppMode.live)
                TextButton(
                  onPressed: _analyze,
                  child: const Text('Retry'),
                ),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _AnalysisResult(assessment: _result!),
            ],
=======
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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
          ],
        ),
      ),
    );
  }
}
<<<<<<< HEAD

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = switch (assessment.level) {
      RiskLevel.low => AppColors.emerald,
      RiskLevel.medium => AppColors.amber,
      RiskLevel.high => AppColors.red,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Risk assessment',
                    style: Theme.of(context).textTheme.titleLarge),
                RiskBadge(level: assessment.level),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: assessment.score / 100,
                      minHeight: 10,
                      color: color,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('${assessment.score}/100',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(assessment.explanation),
            const SizedBox(height: AppSpacing.md),
            Text('Indicators', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final indicator in assessment.indicators)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 7, color: AppColors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(indicator)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const Text('Safer next step',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(assessment.recommendation),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'An automated assessment may be wrong. Reports or risk scores '
              'do not establish guilt.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
=======
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
