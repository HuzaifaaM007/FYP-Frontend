import 'quiz.dart';
export 'quiz.dart';

class GeneratedQuiz {
  final String quizId;
  final int totalQuestions;
  final int totalPoints;
  final String status;
  final List<QuizQuestion> questions;

  GeneratedQuiz({
    required this.quizId,
    required this.totalQuestions,
    required this.totalPoints,
    required this.status,
    required this.questions,
  });

  factory GeneratedQuiz.fromJson(Map<String, dynamic> json) {
    return GeneratedQuiz(
      quizId: json['quiz_id'] as String,
      totalQuestions: json['total_questions'] as int,
      totalPoints: json['total_points'] as int,
      status: json['status'] as String,
      questions: (json['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
    );
  }
}

