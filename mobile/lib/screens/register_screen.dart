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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
<<<<<<< HEAD
  bool _loading = false;
=======
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
<<<<<<< HEAD
    super.dispose();
  }

  Future<void> _register({required bool demo}) async {
    if (!demo && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final mode = demo ? AppMode.demo : AppMode.live;
    SessionService.instance.setMode(mode);
    try {
      await AuthService().register(
        username: _name.text,
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final User user = await _auth.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
      if (mounted) Navigator.of(context).pop(user);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return NumpePage(
      title: 'Create account',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your safer demo starts here',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Enter at least 3 characters.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
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
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'At least 6 characters',
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loading ? null : () => _register(demo: false),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _loading ? null : () => _register(demo: true),
                child: const Text('Explore with a demo session'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Never use your bank password or UPI PIN in this demo app.',
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: _loading
            ? const LoadingIndicator(label: 'Creating account...')
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Create your account',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: validUsername,
                    ),
                    const SizedBox(height: 14),
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
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'At least 6 characters',
                      ),
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
                      onPressed: _register,
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
      );
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
