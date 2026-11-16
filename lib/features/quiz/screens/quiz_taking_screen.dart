import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/quiz_response.dart';
import '../services/quiz_service.dart';
import 'quiz_results_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  final GeneratedQuiz quiz;

  const QuizTakingScreen({super.key, required this.quiz});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final _quizService = QuizService();
  final Map<String, String> _answers = {};
  final Map<String, TextEditingController> _shortAnswerControllers = {};

  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final question in widget.quiz.questions) {
      if (!question.isMultipleChoice) {
        _shortAnswerControllers[question.questionId] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _shortAnswerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _allAnswered {
    return widget.quiz.questions.every((q) {
      final answer = _answers[q.questionId] ?? _shortAnswerControllers[q.questionId]?.text ?? '';
      return answer.trim().isNotEmpty;
    });
  }

  Future<void> _submit() async {
    // Pull final text from short-answer controllers into _answers before sending.
    for (final entry in _shortAnswerControllers.entries) {
      _answers[entry.key] = entry.value.text.trim();
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final submission = await _quizService.submitQuiz(widget.quiz.quizId, _answers);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizResultsScreen(submission: submission, quiz: widget.quiz)),
      );
    } catch (_) {
      setState(() => _error = 'Could not submit your answers. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildQuestion(QuizQuestion question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1} · ${question.points} pt${question.points == 1 ? '' : 's'}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(question.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          if (question.isMultipleChoice)
            ...question.options!.map(
              (option) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: option,
                groupValue: _answers[question.questionId],
                onChanged: (value) => setState(() => _answers[question.questionId] = value!),
                title: Text(option),
              ),
            )
          else
            TextField(
              controller: _shortAnswerControllers[question.questionId],
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Type your answer...'),
              onChanged: (_) => setState(() {}), // refresh the submit-enabled check as they type
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · ${widget.quiz.totalQuestions} questions'),
        automaticallyImplyLeading: false, // don't let users bail mid-quiz via back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.quiz.questions.length,
                itemBuilder: (context, index) => _buildQuestion(widget.quiz.questions[index], index),
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 8),
            ],
            AppButton(
              label: 'Submit Quiz',
              isLoading: _isSubmitting,
              onPressed: _allAnswered ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}