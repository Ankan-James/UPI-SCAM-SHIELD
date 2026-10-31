import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  User? _user;
  bool _checkingServer = false;
  bool _loadingUser = true;
  String? _serverMessage;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _api.close();
    _auth.close();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _auth.currentUser();
      if (mounted) setState(() => _user = user);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _user = null;
          _userError = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _signIn() async {
    final user = await Navigator.of(context).push<User>(
      MaterialPageRoute<User>(builder: (_) => const LoginScreen()),
    );
    if (user != null && mounted) setState(() => _user = user);
  }

  Future<void> _signOut() async {
    try {
      await _auth.logout();
      if (mounted) setState(() => _user = null);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _user = null);
        _showMessage(
          'Signed out on this device, but the server could not revoke the session: $error',
        );
      }
    }
  }

  Future<void> _checkServer() async {
    setState(() {
      _checkingServer = true;
      _serverMessage = null;
    });
    try {
      await _api.checkHealth();
      if (mounted) setState(() => _serverMessage = 'Server is reachable.');
    } on Exception catch (error) {
      if (mounted) setState(() => _serverMessage = error.toString());
    } finally {
      if (mounted) setState(() => _checkingServer = false);
    }
  }

  Future<void> _reportIssue() async {
    final controller = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a concern'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Describe a suspicious message or payment request.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (description == null) return;
    try {
      final status = await _api.report(description);
      if (mounted) _showMessage('Report $status.');
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_loadingUser)
              const ListTile(title: LinearProgressIndicator())
            else if (_user case final user?)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: TextButton(
                    onPressed: _signOut,
                    child: const Text('Sign out'),
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_userError ?? 'Continue without an account'),
                  subtitle: Text(_userError == null
                      ? 'Sign in is optional for scam checks.'
                      : 'Account status could not be checked. Scam checks remain available.'),
                  trailing: TextButton(
                    onPressed: _signIn,
                    child: const Text('Sign in'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Connection', style: Theme.of(context).textTheme.titleLarge),
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
            Card(
              child: Column(
                children: [
                  ListTile(
<<<<<<< HEAD
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
=======
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('API server'),
                    subtitle: SelectableText(apiBaseUrl),
                    trailing: _checkingServer
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Check connection',
                            onPressed: _checkServer,
                            icon: const Icon(Icons.refresh),
                          ),
                  ),
                  if (_serverMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_serverMessage!),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Help', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report suspicious activity'),
                subtitle: const Text('Send a report to the review queue.'),
                onTap: _reportIssue,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Scam Shield provides automated guidance, not financial or legal advice. Verify requests directly with your bank.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
