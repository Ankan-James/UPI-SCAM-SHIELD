import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NumpePage extends StatelessWidget {
  const NumpePage({
    required this.title,
    required this.child,
    this.showBack = true,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBack && Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                'SIMULATED',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
    );
  }
}
