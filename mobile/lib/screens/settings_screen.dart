import 'package:flutter/material.dart';

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
            Card(
              child: Column(
                children: [
                  ListTile(
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
