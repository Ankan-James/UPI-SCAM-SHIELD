import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/numpe_page.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _type = 'upi_id';
  bool _sending = false;
  String? _reportStatus;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
      _reportStatus = null;
    });

    try {
      String status;
      if (SessionService.instance.mode == AppMode.demo) {
        MockDataService.demoReports.add((
          type: _type,
          description: _description.text.trim(),
          date: DateTime.now(),
        ));
        status = 'Demo report saved locally for this session. '
            'It has not been sent to authorities or reviewed.';
      } else {
        final response = await ApiService().post('reports', body: {
          'report_type': _type,
          'description': _description.text.trim(),
        });
        if (response['id'] == null || response['status'] is! String) {
          throw const ApiException(
            'The server returned an invalid report status.',
          );
        }
        status = 'Report reference ${response['id']}: ${response['status']}. '
            'The backend did not confirm an authority notification.';
      }
      if (mounted) setState(() => _reportStatus = status);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Report a concern',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tell us what happened',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Include only details needed to describe the concern. Never '
                'include passwords, PINs, OTPs or full card details.',
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Report category'),
                items: const [
                  DropdownMenuItem(value: 'upi_id', child: Text('Recipient ID')),
                  DropdownMenuItem(value: 'message', child: Text('Message or call')),
                  DropdownMenuItem(value: 'url', child: Text('Website or link')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'other'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a brief description.'
                    : null,
              ),
              FilledButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.red)),
              ],
              if (_reportStatus != null) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(_reportStatus!),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Text(
                'This feature does not automatically contact a bank, police, '
                'or cybercrime authority.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
