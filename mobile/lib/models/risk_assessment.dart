enum RiskLevel { low, medium, high }

class RiskAssessment {
  const RiskAssessment({
    required this.score,
    required this.level,
    required this.explanation,
    required this.indicators,
    required this.recommendation,
  });

  final int score;
  final RiskLevel level;
  final String explanation;
  final List<String> indicators;
  final String recommendation;

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    final scoreValue = json['score'];
    if (scoreValue is! num || scoreValue < 0 || scoreValue > 100) {
      throw const FormatException('Risk response has an invalid score.');
    }

    final level = switch ('${json['level']}'.toLowerCase()) {
      'low' => RiskLevel.low,
      'medium' => RiskLevel.medium,
      'high' => RiskLevel.high,
      _ => _levelForScore(scoreValue.toInt()),
    };
    final indicatorsValue = json['indicators'];

    return RiskAssessment(
      score: scoreValue.toInt(),
      level: level,
      explanation: json['explanation'] is String
          ? json['explanation'] as String
          : 'This assessment is an estimate, not proof of fraud.',
      indicators: indicatorsValue is List
          ? indicatorsValue.map((value) => value.toString()).toList()
          : const [],
      recommendation: json['recommendation'] is String
          ? json['recommendation'] as String
          : 'Verify the recipient using a trusted channel.',
    );
  }

  static RiskLevel _levelForScore(int score) {
    if (score >= 70) return RiskLevel.high;
    if (score >= 35) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
