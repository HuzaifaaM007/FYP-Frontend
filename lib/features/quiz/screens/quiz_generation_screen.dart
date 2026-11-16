import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/quiz_response.dart';
import '../services/quiz_service.dart';
import 'quiz_taking_screen.dart';
import '../../../shared/widgets/ai_gate.dart';

class QuizGenerationScreen extends StatefulWidget {
  final String? lectureId;
  final String? lessonId;

  const QuizGenerationScreen({super.key, this.lectureId, this.lessonId})
      : assert(lectureId != null || lessonId != null, 'Provide either a lectureId or a lessonId');

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  final _quizService = QuizService();

  int _numMcq = 5;
  int _numShort = 3;
  bool _isGenerating = false;
  String? _error;

  Future<void> _generate() async {
    if (!await AiGate.check(context)) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final GeneratedQuiz quiz = widget.lectureId != null
          ? await _quizService.generateQuizFromLecture(widget.lectureId!, numMcq: _numMcq, numShort: _numShort)
          : await _quizService.generateQuizFromLesson(widget.lessonId!, numMcq: _numMcq, numShort: _numShort);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizTakingScreen(quiz: quiz)),
      );
    } catch (_) {
      setState(() => _error = 'Could not generate a quiz right now. Please try again.');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Widget _counterRow(String label, int value, ValueChanged<int> onChanged, {int min = 0, int max = 15}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose how many questions to generate from this content.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _counterRow('Multiple choice questions', _numMcq, (v) => setState(() => _numMcq = v), min: 1, max: 15),
            const SizedBox(height: 8),
            _counterRow('Short answer questions', _numShort, (v) => setState(() => _numShort = v), min: 0, max: 10),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Generate Quiz',
              isLoading: _isGenerating,
              onPressed: (_numMcq + _numShort) > 0 ? _generate : null,
            ),
          ],
        ),
      ),
    );
  }
}