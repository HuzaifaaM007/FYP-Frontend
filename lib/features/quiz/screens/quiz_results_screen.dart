import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/quiz_response.dart';
import '../models/submission.dart';

class QuizResultsScreen extends StatelessWidget {
  final QuizSubmission submission;
  final GeneratedQuiz quiz;

  const QuizResultsScreen({super.key, required this.submission, required this.quiz});

  Color _scoreColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  QuizQuestion? _findQuestion(String questionId) {
    for (final q in quiz.questions) {
      if (q.questionId == questionId) return q;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(submission.percentage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Score summary card ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  '${submission.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(color: scoreColor, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${submission.totalScore} / ${submission.totalPoints} points',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Question Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...submission.answers.map((result) {
            final question = _findQuestion(result.questionId);
            return _AnswerCard(result: result, question: question);
          }),

          const SizedBox(height: 8),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/home'),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final AnswerResult result;
  final QuizQuestion? question;

  const _AnswerCard({required this.result, required this.question});

  @override
  Widget build(BuildContext context) {
    final statusColor = result.isCorrect ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.isCorrect ? Icons.check_circle : Icons.cancel,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question?.questionText ?? 'Question',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${result.pointsEarned} pt${result.pointsEarned == 1 ? '' : 's'}',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Your answer: ${result.studentAnswer}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (question?.questionType == 'short_answer') ...[
            const SizedBox(height: 4),
            Text(
              'Match confidence: ${(result.similarityScore * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          if (result.feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(result.feedback, style: const TextStyle(fontSize: 13)),
            ),
          ],
          if (question?.explanation != null) ...[
            const SizedBox(height: 6),
            Text(
              'Explanation: ${question!.explanation}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}