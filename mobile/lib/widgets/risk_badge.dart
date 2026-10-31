import 'package:flutter/material.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.level, super.key});

  final String level;

  @override
  Widget build(BuildContext context) {
    final normalized = level.toUpperCase();
    final color = switch (normalized) {
      'HIGH' => const Color(0xFFB42318),
      'MEDIUM' => const Color(0xFFB54708),
      _ => const Color(0xFF087F5B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$normalized RISK',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
