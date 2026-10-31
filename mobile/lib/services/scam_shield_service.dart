import '../config/api_config.dart';
import '../models/risk_assessment.dart';
import 'api_service.dart';

class ScamShieldService {
  ScamShieldService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<RiskAssessment> analyze({
    required String input,
    required String type,
    required AppMode mode,
  }) async {
    if (input.trim().isEmpty) {
      throw const ApiException('Enter something to check.');
    }
    if (mode == AppMode.demo) return _analyzeDemo(input.trim(), type);

    final response = await _api.post('analyze', body: {
      'type': type,
      'input': input.trim(),
    });
    return RiskAssessment.fromJson(response);
  }

  RiskAssessment _analyzeDemo(String input, String type) {
    final normalized = input.toLowerCase();
    final indicators = <String>[];
    var score = 8;

    if (normalized.contains('urgent') ||
        normalized.contains('act now') ||
        normalized.contains('immediately')) {
      score += 27;
      indicators.add('Urgent language may pressure people into acting quickly.');
    }
    if (normalized.contains('otp') ||
        normalized.contains('pin') ||
        normalized.contains('password')) {
      score += 50;
      indicators.add('The message asks for a sensitive credential.');
    }
    if (normalized.contains('collect request') ||
        normalized.contains('approve to receive')) {
      score += 42;
      indicators.add('A collect request is presented as a way to receive money.');
    }
    if (type == 'url') {
      final uri = Uri.tryParse(input);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        score += 35;
        indicators.add('This does not look like a complete web address.');
      } else if (uri.scheme != 'https') {
        score += 22;
        indicators.add('The link does not use a secure HTTPS connection.');
      }
      if (normalized.contains('bit.ly') ||
          normalized.contains('tinyurl') ||
          normalized.contains('free-gift')) {
        score += 28;
        indicators.add('The link uses a shortener or an unexpected offer.');
      }
    }
    if (type == 'upi_id' &&
        !RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z0-9.-]{2,}$')
            .hasMatch(input)) {
      score += 40;
      indicators.add('The recipient ID does not match the expected UPI ID format.');
    }

    score = score.clamp(0, 100).toInt();
    final level = score >= 70
        ? RiskLevel.high
        : score >= 35
            ? RiskLevel.medium
            : RiskLevel.low;
    return RiskAssessment(
      score: score,
      level: level,
      explanation: 'Demo screening found ${indicators.isEmpty ? 'few' : 'some'} '
          'risk signals. This estimate is not proof of fraud.',
      indicators: indicators.isEmpty
          ? const ['No common warning patterns were found in this demo check.']
          : indicators,
      recommendation: level == RiskLevel.high
          ? 'Do not proceed until you independently verify the recipient.'
          : 'Verify the recipient and payment details through a trusted channel.',
    );
  }
}
