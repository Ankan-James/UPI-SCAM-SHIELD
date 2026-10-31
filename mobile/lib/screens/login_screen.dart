import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/numpe_page.dart';
=======

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/loading_indicator.dart';
import 'register_screen.dart';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
<<<<<<< HEAD
=======
  String? _error;
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
<<<<<<< HEAD
    super.dispose();
  }

  Future<void> _login({required bool demo}) async {
    if (!demo && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final mode = demo ? AppMode.demo : AppMode.live;
    SessionService.instance.setMode(mode);
    try {
      await _auth.login(
        email: _email.text,
        password: _password.text,
        mode: mode,
      );
      if (mounted) context.go('/home');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
=======
    _auth.close();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final User user = await _auth.login(_email.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop(user);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Welcome back',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sign in to NUMPE',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('Choose demo mode to explore safely without an account.'),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loading ? null : () => _login(demo: false),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _loading ? null : () => _login(demo: true),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Continue in demo mode'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('New to NUMPE? Create an account'),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Live mode sends credentials only to your configured backend. '
                'Passwords are not saved on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
=======
  Future<void> _register() async {
    final user = await Navigator.of(context).push<User>(
      MaterialPageRoute<User>(builder: (_) => const RegisterScreen()),
    );
    if (user != null && mounted) Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: _loading
            ? const LoadingIndicator(label: 'Signing in...')
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Sign in to your Scam Shield account.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: validEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: validPassword,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _login,
                      child: const Text('Sign in'),
                    ),
                    TextButton(
                      onPressed: _register,
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
      );
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
