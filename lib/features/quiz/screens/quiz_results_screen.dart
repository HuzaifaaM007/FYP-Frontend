import 'package:flutter/material.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/brain.dart';
import '../models/quiz_response.dart';
import '../models/submission.dart';
import '../services/brain_service.dart';
import '../widgets/brain_panel.dart';

class QuizResultsScreen extends StatefulWidget {
  final QuizSubmission submission;
  final GeneratedQuiz quiz;

  const QuizResultsScreen({super.key, required this.submission, required this.quiz});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final _brainApi = BrainApiService();
  Map<String, BrainWalkthrough>? _brain;
  bool _brainLoading = true;
  String? _brainError;

  @override
  void initState() {
    super.initState();
    _loadBrain(); // start right away, so it is usually ready by the time the student taps
  }

  Future<void> _loadBrain() async {
    setState(() {
      _brainLoading = true;
      _brainError = null;
    });
    try {
      final data = await _brainApi.forQuiz(widget.submission.quizId);
      if (!mounted) return;
      setState(() {
        _brain = data;
        _brainLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _brainLoading = false;
        _brainError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Color _scoreColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  QuizQuestion? _findQuestion(String questionId) {
    for (final q in widget.quiz.questions) {
      if (q.questionId == questionId) return q;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final scoreColor = _scoreColor(submission.percentage);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text('${submission.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(color: scoreColor, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${submission.totalScore} / ${submission.totalPoints} points',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Question Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              TextButton.icon(
                onPressed: () => showBrainIntro(context),
                icon: Icon(Icons.psychology_alt_outlined, size: 18, color: AppColors.accentPurple),
                label: Text('What is BRAIN?', style: TextStyle(color: AppColors.accentPurple, fontSize: 13)),
              ),
            ],
          ),
          if (_brainLoading)
            _BrainStatus(
              icon: Icons.hourglass_top_rounded,
              text: 'Preparing BRAIN breakdowns… The first time can take up to a minute; after that they open instantly.',
            )
          else if (_brainError != null)
            _BrainStatus(icon: Icons.info_outline, text: _brainError!, onRetry: _loadBrain),
          const SizedBox(height: 12),
          ...submission.answers.map((result) => _AnswerCard(
                result: result,
                question: _findQuestion(result.questionId),
                brain: _brain?[result.questionId],
                brainLoading: _brainLoading,
              )),
          const SizedBox(height: 8),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
          ),
        ],
      ),
    );
  }
}

class _BrainStatus extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _BrainStatus({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatefulWidget {
  final AnswerResult result;
  final QuizQuestion? question;
  final BrainWalkthrough? brain;
  final bool brainLoading;

  const _AnswerCard({required this.result, required this.question, required this.brain, required this.brainLoading});

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final question = widget.question;
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
              Icon(result.isCorrect ? Icons.check_circle : Icons.cancel, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question?.questionText ?? 'Question',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              Text('${result.pointsEarned} pt${result.pointsEarned == 1 ? '' : 's'}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Your answer: ${result.studentAnswer}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (!result.isCorrect && result.correctAnswer != null && result.correctAnswer!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Correct answer: ${result.correctAnswer}',
                style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          if (question?.questionType == 'short_answer') ...[
            const SizedBox(height: 4),
            Text('Match confidence: ${(result.similarityScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          if (result.feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
              child: Text(result.feedback, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
          ],
          if (question?.explanation != null) ...[
            const SizedBox(height: 6),
            Text('Explanation: ${question!.explanation}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          // BRAIN breakdown toggle
          if (widget.brain != null || widget.brainLoading)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.brain == null ? null : () => setState(() => _open = !_open),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_alt_outlined, size: 18, color: AppColors.accentPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.brain == null ? 'BRAIN breakdown is being prepared…' : (_open ? 'Hide BRAIN breakdown' : 'Show BRAIN breakdown'),
                        style: TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    if (widget.brain == null)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple))
                    else
                      Icon(_open ? Icons.expand_less : Icons.expand_more, color: AppColors.accentPurple),
                  ],
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open && widget.brain != null
                ? Padding(padding: const EdgeInsets.only(top: 14), child: BrainPanel(w: widget.brain!))
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
