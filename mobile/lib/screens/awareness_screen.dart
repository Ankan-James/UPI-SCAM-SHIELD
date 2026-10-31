import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class AwarenessScreen extends StatelessWidget {
  const AwarenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.lock_outline,
        'Never share your UPI PIN or OTP',
        'A PIN is used to authorize a payment. You do not need to enter it to receive money.',
      ),
      (
        Icons.call_received_outlined,
        'Receiving money does not require approval',
        'Be cautious if someone asks you to scan a QR code or approve a collect request to receive funds.',
      ),
      (
        Icons.link_outlined,
        'Pause before opening unexpected links',
        'Check the full website address and use an official app or known contact to verify requests.',
      ),
      (
        Icons.support_agent_outlined,
        'Verify unexpected support calls',
        'End the call and contact the organization using contact details you find independently.',
      ),
      (
        Icons.timer_outlined,
        'Urgency is a reason to slow down',
        'Pressure, threats or surprise rewards can make it harder to review a payment carefully.',
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UPI Scam Shield',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Practical reminders to help you pause, verify and stay safer.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.blue,
                    size: 32,
                  ),
                  title: const Text('Check suspicious content'),
                  subtitle: const Text(
                    'Assess a message, website link or payment recipient.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/analyze'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (icon, title, body) in tips)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: Icon(icon, color: AppColors.blue),
                    title: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(body),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.push('/report'),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Submit a scam report'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Safety tip: In India, call 1930 promptly to report suspected '
                'financial cyber fraud. NUMPE does not send reports to authorities.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}