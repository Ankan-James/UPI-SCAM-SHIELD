import 'package:flutter/material.dart';

import '../models/risk_assessment.dart';
import '../theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.level, super.key});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (level) {
      RiskLevel.low => ('Low risk', AppColors.emerald, Icons.verified_user),
      RiskLevel.medium => ('Medium risk', AppColors.amber, Icons.warning_amber),
      RiskLevel.high => ('High risk', AppColors.red, Icons.gpp_bad),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}