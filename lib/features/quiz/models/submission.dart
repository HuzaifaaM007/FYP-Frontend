class AnswerResult {
  final String questionId;
  final String studentAnswer;
  final bool isCorrect;
  final double similarityScore;
  final int pointsEarned;
  final String feedback;
  final double confidence;
  final String? rubricNotes;
  final String? correctAnswer;

  AnswerResult({
    required this.questionId,
    required this.studentAnswer,
    required this.isCorrect,
    required this.similarityScore,
    required this.pointsEarned,
    required this.feedback,
    required this.confidence,
    this.rubricNotes,
    this.correctAnswer,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      questionId: json['question_id'] as String,
      studentAnswer: json['student_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      similarityScore: (json['similarity_score'] as num).toDouble(),
      pointsEarned: json['points_earned'] as int,
      feedback: json['feedback'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      rubricNotes: json['rubric_notes'] as String?,
      correctAnswer: json['correct_answer'] as String?,
    );
  }
}

class QuizSubmission {
  final String submissionId;
  final String quizId;
  final int totalScore;
  final int totalPoints;
  final double percentage;
  final List<AnswerResult> answers;

  QuizSubmission({
    required this.submissionId,
    required this.quizId,
    required this.totalScore,
    required this.totalPoints,
    required this.percentage,
    required this.answers,
  });

  factory QuizSubmission.fromJson(Map<String, dynamic> json) {
    return QuizSubmission(
      submissionId: json['submission_id'] as String,
      quizId: json['quiz_id'] as String,
      totalScore: json['total_score'] as int,
      totalPoints: json['total_points'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      answers: (json['answers'] as List).map((a) => AnswerResult.fromJson(a)).toList(),
    );
  }
}