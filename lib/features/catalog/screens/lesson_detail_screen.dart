import 'package:flutter/material.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/audio_player_widget.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/markdown_view.dart';
import '../../quiz/screens/quiz_generation_screen.dart';
import '../models/lesson.dart';
import '../services/catalog_service.dart';

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

  String? _audioUrl;
  bool _isGeneratingAudio = false;

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

  Future<void> _generateAudio() async {
    setState(() => _isGeneratingAudio = true);
    try {
      final response = await ApiClient().dio.post('/catalog/lessons/${widget.lessonId}/audio', data: {});
      // Windows servers used to store backslashes; normalise so the URL always works.
      final relativePath = (response.data['file_path'] as String).replaceAll('\\', '/');
      if (mounted) setState(() => _audioUrl = '${Env.apiBaseUrl}/$relativePath');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate audio. The voice service may be starting up; try again in a minute.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lesson?.title ?? 'Lesson', overflow: TextOverflow.ellipsis)),
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
        Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 6),
        Text('${lesson.estimatedMinutes} min read · ${lesson.difficulty}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: MarkdownView(data: lesson.contentText),
        ),
        if (lesson.attribution.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(lesson.attribution, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
        ],
        const SizedBox(height: 20),
        if (lesson.audioEligible) ...[
          if (_audioUrl != null)
            AudioPlayerWidget(audioUrl: _audioUrl!)
          else
            AppButton(label: 'Listen to Lesson', outlined: true, isLoading: _isGeneratingAudio, onPressed: _generateAudio),
          const SizedBox(height: 12),
        ],
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
