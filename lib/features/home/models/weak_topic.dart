class WeakTopic {
  final String topicId;
  final String title;
  final double averageScore;
  final int attempts;

  WeakTopic({
    required this.topicId,
    required this.title,
    required this.averageScore,
    required this.attempts,
  });

  factory WeakTopic.fromJson(Map<String, dynamic> json) {
    return WeakTopic(
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      averageScore: (json['average_score'] as num).toDouble(),
      attempts: json['attempts'] as int,
    );
  }
}