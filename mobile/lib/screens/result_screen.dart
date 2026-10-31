import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../widgets/risk_badge.dart';
import '../widgets/scan_result_card.dart';
import '../widgets/voice_player.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.result, super.key});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final isHigh = result.level == 'HIGH';
    final title = switch (result.level) {
      'HIGH' => 'Be very cautious',
      'MEDIUM' => 'Check before acting',
      _ => 'No strong warning signs found',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Safety check')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            isHigh ? Icons.gpp_bad_outlined : Icons.verified_user_outlined,
            size: 58,
            color: isHigh ? const Color(0xFFB42318) : const Color(0xFF087F5B),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 18),
          ScanResultCard(result: result),
          if (result.indicators.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('What stood out',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...result.indicators.map(
              (indicator) => Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(indicator),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text('Recommended next step',
              style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(result.recommendation,
                  style: const TextStyle(height: 1.5)),
            ),
          ),
          const SizedBox(height: 8),
          VoicePlayer(result: result),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Check something else'),
          ),
          const SizedBox(height: 12),
          const Text(
            'A low-risk result does not prove that a message or payment is safe. Verify through official channels.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          RiskBadge(level: result.level),
        ],
      ),
    );
  }
}
