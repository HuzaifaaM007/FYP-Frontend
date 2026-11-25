/// One row in the "My Quizzes" list.
class MyQuizItem {
  final String quizId;
  final String title;
  final String? courseTitle;
  final int totalQuestions;
  final int totalPoints;
  final DateTime? createdAt;
  final bool submitted;
  final int? totalScore;
  final double? percentage;
  final DateTime? submittedAt;

  MyQuizItem({
    required this.quizId,
    required this.title,
    this.courseTitle,
    required this.totalQuestions,
    required this.totalPoints,
    this.createdAt,
    required this.submitted,
    this.totalScore,
    this.percentage,
    this.submittedAt,
  });

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory MyQuizItem.fromJson(Map<String, dynamic> json) {
    return MyQuizItem(
      quizId: json['quiz_id'] as String,
      title: (json['title'] as String?) ?? 'Quiz',
      courseTitle: json['course_title'] as String?,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['created_at']),
      submitted: json['submitted'] == true,
      totalScore: (json['total_score'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      submittedAt: _date(json['submitted_at']),
    );
  }
}
