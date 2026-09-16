import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../models/lesson.dart';
import '../services/catalog_service.dart';
import '../../quiz/screens/quiz_generation_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _service = CatalogApiService();
  Lesson? _lesson;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _lesson = await _service.fetchLesson(widget.lessonId);
    } catch (_) {
      _error = 'Could not load this lesson.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lesson?.title ?? 'Lesson')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final lesson = _lesson!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(lesson.summary, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        // NOTE: contentText often contains code blocks (see the seeded course
        // content). Rendering it in a plain monospace SelectableText for now
        // so code is at least readable; a proper syntax-highlighted renderer
        // (flutter_highlight) is worth swapping in here later — flagged
        // rather than silently shipping unreadable code blocks.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(
            lesson.contentText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        if (lesson.quizEligible)
          AppButton(
            label: 'Generate Quiz',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizGenerationScreen(lessonId: lesson.lessonId)),
            ),
          ),
      ],
    );
  }
}