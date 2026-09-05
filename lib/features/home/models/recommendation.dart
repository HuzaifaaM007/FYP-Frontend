class RecommendationItem {
  final String recommendationId;
  final String targetType;
  final String targetId;
  final double score;
  final String reasonCode;
  final String explanation;

  RecommendationItem({
    required this.recommendationId,
    required this.targetType,
    required this.targetId,
    required this.score,
    required this.reasonCode,
    required this.explanation,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      recommendationId: json['recommendation_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      score: (json['score'] as num).toDouble(),
      reasonCode: json['reason_code'] as String,
      explanation: json['explanation'] as String,
    );
  }
}