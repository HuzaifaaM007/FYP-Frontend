import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/audio_player_widget.dart';
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
      final relativePath = response.data['file_path'] as String; // e.g. "storage/catalog_assets/xyz.wav"
      setState(() => _audioUrl = '${Env.apiBaseUrl}/$relativePath');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate audio for this lesson.')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAudio = false);
    }
  }

  // Maps the language name written in our seeded content's
  // "Code Example (Language - ...)" marker to flutter_highlight's language keys.
  String _mapLanguage(String? detected) {
    switch (detected?.toLowerCase().trim()) {
      case 'c#':
      case 'csharp':
        return 'csharp';
      case 'java':
        return 'java';
      case 'html':
        return 'xml'; // flutter_highlight uses 'xml' for HTML-like markup
      case 'css':
        return 'css';
      case 'javascript':
      case 'js':
        return 'javascript';
      case 'react native':
      case 'jsx':
        return 'javascript';
      case 'shell':
      case 'bash':
        return 'bash';
      case 'json':
        return 'json';
      default:
        return 'plaintext';
    }
  }

  Widget _buildContentWithCode(String text) {
    final blocks = <Widget>[];
    final lines = text.split('\n');
    final proseBuffer = StringBuffer();
    final codeBuffer = StringBuffer();
    bool inCodeBlock = false;
    String currentLanguage = 'plaintext';

    void flushProse() {
      if (proseBuffer.toString().trim().isNotEmpty) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText(proseBuffer.toString().trim(), style: const TextStyle(height: 1.5)),
        ));
      }
      proseBuffer.clear();
    }

    void flushCode() {
      if (codeBuffer.toString().trim().isNotEmpty) {
        blocks.add(Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              codeBuffer.toString().trim(),
              language: currentLanguage,
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
        ));
      }
      codeBuffer.clear();
    }

    final markerPattern = RegExp(r'Code Example\s*\(([^)-]+)', caseSensitive: false);

    for (final line in lines) {
      final match = markerPattern.firstMatch(line.trimLeft());
      if (line.trimLeft().startsWith('Code Example') && match != null) {
        flushProse();
        currentLanguage = _mapLanguage(match.group(1));
        inCodeBlock = true;
        continue;
      }
      if (inCodeBlock && line.trim().isEmpty && codeBuffer.isNotEmpty) {
        flushCode();
        inCodeBlock = false;
        continue;
      }
      if (inCodeBlock) {
        codeBuffer.writeln(line);
      } else {
        proseBuffer.writeln(line);
      }
    }
    flushProse();
    flushCode();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
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
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: _buildContentWithCode(lesson.contentText),
        ),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizGenerationScreen(lessonId: lesson.lessonId))),
          ),
      ],
    );
  }
}