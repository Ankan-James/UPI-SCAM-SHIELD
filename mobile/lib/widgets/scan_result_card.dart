import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import 'risk_badge.dart';

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({required this.result, super.key});

  final ScanResult result;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${result.score}/100',
                      style: Theme.of(context).textTheme.headlineSmall),
                  RiskBadge(level: result.level),
                ],
              ),
              const SizedBox(height: 12),
              Text(result.explanation ?? result.recommendation),
            ],
          ),
        ),
      );
}
