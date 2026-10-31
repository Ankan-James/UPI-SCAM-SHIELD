import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessionService.instance,
      builder: (context, _) {
        final session = SessionService.instance;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Profile & security',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Manage this simulated NUMPE session.'),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A4361EE),
                  child: Icon(Icons.person, color: AppColors.blue),
                ),
                title: Text(
                  session.mode == AppMode.demo
                      ? 'Disha Naskar · Demo'
                      : 'Account identity unavailable',
                ),
                subtitle: Text(
                  '${session.mode == AppMode.demo ? 'Demo account' : 'Live backend'}'
                  ' · ${session.isAuthenticated ? 'Signed in' : 'Guest session'}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.lock_outline_rounded),
                title: const Text('Emergency Payment Lock'),
                subtitle: const Text(
                  'Session-only safety gate. Not a bank or server lock.',
                ),
                value: session.emergencyLockEnabled,
                onChanged: session.setEmergencyLock,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Demo mode'),
                    subtitle: const Text(
                      'Deterministic sample data; no backend request.',
                    ),
                    trailing: Radio<AppMode>(
                      value: AppMode.demo,
                      groupValue: session.mode,
                      onChanged: (mode) {
                        if (mode != null) session.setMode(mode);
                      },
                    ),
                    onTap: () => session.setMode(AppMode.demo),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Live backend'),
                    subtitle: const Text(
                      'API errors stay visible; no fake payment success.',
                    ),
                    trailing: Radio<AppMode>(
                      value: AppMode.live,
                      groupValue: session.mode,
                      onChanged: (mode) {
                        if (mode != null) session.setMode(mode);
                      },
                    ),
                    onTap: () => session.setMode(AppMode.live),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'NUMPE is a demonstration. It cannot access bank '
                        'accounts or perform real UPI payments.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await AuthService().logout(mode: session.mode);
                  if (context.mounted) context.go('/welcome');
                } on ApiException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }
}