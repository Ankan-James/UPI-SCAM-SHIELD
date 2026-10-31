import '../config/api_config.dart';
import '../models/risk_assessment.dart';
import 'scam_shield_service.dart';

class ScanService {
  ScanService({
    required this.mode,
    ScamShieldService? shield,
  }) : _shield = shield ?? ScamShieldService();

  final AppMode mode;
  final ScamShieldService _shield;

  Future<RiskAssessment> analyzeText(String text) => _shield.analyze(
        input: text,
        type: 'text',
        mode: mode,
      );
}