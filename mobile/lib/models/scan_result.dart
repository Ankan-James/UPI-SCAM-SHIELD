class ScanResult {
  const ScanResult({
    required this.score,
    required this.level,
    required this.indicators,
    required this.recommendation,
    required this.type,
    this.analysisId,
    this.explanation,
  });

  final int score;
  final String level;
  final List<String> indicators;
  final String recommendation;
  final String type;
  final String? analysisId;
  final String? explanation;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final rawIndicators = json['indicators'] as List<dynamic>? ?? const [];
    return ScanResult(
      score: (json['score'] as num?)?.toInt() ??
          (json['risk_score'] as num?)?.toInt() ??
          0,
      level:
          (json['level'] as String? ?? json['risk_level'] as String? ?? 'LOW')
              .toUpperCase(),
      indicators: rawIndicators.map((item) {
        if (item is String) return item;
        if (item is Map<String, dynamic>) {
          return item['evidence'] as String? ??
              item['explanation'] as String? ??
              'Risk indicator detected';
        }
        return item.toString();
      }).toList(),
      recommendation: json['recommendation'] as String? ??
          'Verify the source before acting.',
      type: json['type'] as String? ?? json['input_type'] as String? ?? 'text',
      analysisId: json['analysis_id'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  factory ScanResult.fromHistory(Map<String, dynamic> json) => ScanResult(
        score: (json['risk_score'] as num?)?.toInt() ?? 0,
        level: (json['risk_level'] as String? ?? 'LOW').toUpperCase(),
        indicators: const [],
        recommendation: 'Open a new scan to see recommendations.',
        type: json['input_type'] as String? ?? 'text',
        analysisId: json['analysis_id']?.toString(),
      );
}
