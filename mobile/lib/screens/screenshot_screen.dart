import 'package:flutter/material.dart';

import 'scan_screen.dart';

class ScreenshotScreen extends StatelessWidget {
  const ScreenshotScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Check a screenshot')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_search_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Copy the message text from your screenshot',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Automatic screenshot text extraction is not available yet. You can paste the visible text into a manual check.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ScanScreen(initialType: 'screenshot'),
                  ),
                ),
                child: const Text('Paste message text'),
              ),
            ],
          ),
        ),
      );
}
