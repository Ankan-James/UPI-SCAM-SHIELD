import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/numpe_page.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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