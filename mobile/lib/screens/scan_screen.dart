import 'package:flutter/material.dart';

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

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final TextEditingController _input;
  String _type = 'text';
  bool _loading = false;
  String? _error;
  RiskAssessment? _result;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialInput);
    if (widget.initialInput != null) {
      final uri = Uri.tryParse(widget.initialInput!);
      _type = uri?.hasScheme == true ? 'url' : 'text';
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}

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