class QuizQuestion {
  final String questionId;
  final String sourceType;
  final String? sourceRefId;
  final String questionText;
  final String questionType; // "mcq" or "short_answer" — confirm exact values against a real response
  final List<String>? options;
  final int points;
  final String? explanation;

  QuizQuestion({
    required this.questionId,
    required this.sourceType,
    this.sourceRefId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.points,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionId: json['question_id'] as String,
      sourceType: json['source_type'] as String,
      sourceRefId: json['source_ref_id'] as String?,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      options: (json['options'] as List?)?.map((o) => o.toString()).toList(),
      points: json['points'] as int,
      explanation: json['explanation'] as String?,
    );
  }

  bool get isMultipleChoice => options != null && options!.isNotEmpty;
}