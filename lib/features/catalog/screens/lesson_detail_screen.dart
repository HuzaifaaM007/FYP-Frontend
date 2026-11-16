import 'dart:async';
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

class _LessonDetailScreenState extends State<LessonDetailScreen> with WidgetsBindingObserver {
  final _service = CatalogApiService();
  Lesson? _lesson;
  bool _isLoading = true;
  String? _error;

  String? _audioUrl;
  bool _isGeneratingAudio = false;

  // Reading progress: how far the student scrolled, and how long they actually spent here.
  final _scroll = ScrollController();
  Timer? _timer;
  int _seconds = 0;
  double _percent = 0; // 0..1, furthest point reached
  bool _completed = false;
  bool _reporting = false;
  int _reportFailures = 0;
  bool _foreground = true;
  int _shownPercent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  void _tick() {
    if (_lesson == null || _completed || !mounted) return;
    if (_foreground) _seconds++;
    if (_scroll.hasClients) {
      final max = _scroll.position.maxScrollExtent;
      final p = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
      if (p > _percent) _percent = p;
    }
    // Same rule as the server: 30% of the estimated reading time, between 10 and 90 seconds.
    final needed = (_lesson!.estimatedMinutes * 60 * 0.3).clamp(10, 90);
    if (_percent >= 0.9 && _seconds >= needed) _maybeReport();
    final shown = (_percent * 100).round();
    if (shown != _shownPercent && mounted) {
      _shownPercent = shown;
      setState(() {});
    }
  }

  Future<void> _maybeReport() async {
    if (_reporting || _completed || _reportFailures >= 3) return;
    _reporting = true;
    try {
      final done = await _service.reportProgress(
        kind: 'lesson',
        entityId: widget.lessonId,
        percent: _percent * 100,
        seconds: _seconds,
      );
      // Not accepted yet (read too quickly): keep going, the next ticks will retry as time passes.
      if (done && mounted) {
        setState(() => _completed = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson completed')));
      }
    } catch (_) {
      _reportFailures++;
    } finally {
      _reporting = false;
    }
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
    return Column(
      children: [
        LinearProgressIndicator(
          value: _completed ? 1 : _percent,
          minHeight: 3,
          backgroundColor: AppColors.surfaceElevated,
          valueColor: AlwaysStoppedAnimation(_completed ? AppColors.accentGreen : AppColors.accentBlue),
        ),
        Expanded(child: _lessonList(lesson)),
      ],
    );
  }

  Widget _lessonList(Lesson lesson) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: [
        Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 6),
        Text(
            '${lesson.estimatedMinutes} min read · ${lesson.difficulty}'
            '${_completed ? ' · Completed ✓' : ' · ${(_percent * 100).round()}% read'}',
            style: TextStyle(color: _completed ? AppColors.accentGreen : AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: MarkdownView(data: lesson.contentText),
        ),
        if (lesson.attribution.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(lesson.attribution, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
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
