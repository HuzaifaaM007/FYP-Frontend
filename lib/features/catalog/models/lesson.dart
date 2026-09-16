class Lesson {
  final String lessonId;
  final String title;
  final String summary;
  final String contentText;
  final int orderIndex;
  final int estimatedMinutes;
  final String difficulty;
  final String sourceUrl;
  final bool quizEligible;
  final bool audioEligible;

  Lesson({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.contentText,
    required this.orderIndex,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.sourceUrl,
    required this.quizEligible,
    required this.audioEligible,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      contentText: json['content_text'] as String,
      orderIndex: json['order_index'] as int,
      estimatedMinutes: json['estimated_minutes'] as int,
      difficulty: json['difficulty'] as String,
      sourceUrl: json['source_url'] as String,
      quizEligible: json['quiz_eligible'] as bool,
      audioEligible: json['audio_eligible'] as bool,
    );
  }
}