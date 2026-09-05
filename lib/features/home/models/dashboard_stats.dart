class DashboardStats {
  final int totalUploads;
  final int totalQuizzesTaken;
  final int totalStudyEvents;
  final double averageScore;
  final int topicAudioPlays;
  final int recommendationInteractions;

  DashboardStats({
    required this.totalUploads,
    required this.totalQuizzesTaken,
    required this.totalStudyEvents,
    required this.averageScore,
    required this.topicAudioPlays,
    required this.recommendationInteractions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUploads: json['total_uploads'] as int,
      totalQuizzesTaken: json['total_quizzes_taken'] as int,
      totalStudyEvents: json['total_study_events'] as int,
      averageScore: (json['average_score'] as num).toDouble(),
      topicAudioPlays: json['topic_audio_plays'] as int,
      recommendationInteractions: json['recommendation_interactions'] as int,
    );
  }
}