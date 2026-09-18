// lib/features/lectures/screens/lecture_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/topic_tile.dart';
import '../providers/lecture_detail_provider.dart';
import '../../quiz/screens/quiz_generation_screen.dart';

class LectureDetailScreen extends StatefulWidget {
  final String lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  late final LectureDetailProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = LectureDetailProvider();
    _provider.load(widget.lectureId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<LectureDetailProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(title: Text(provider.lecture?.title ?? 'Lecture')),
            body: _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(LectureDetailProvider provider) {
    if (provider.state == LectureDetailState.loading) {
      return const LoadingView();
    }
    if (provider.state == LectureDetailState.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: () => provider.load(widget.lectureId),
      );
    }

    final lecture = provider.lecture!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Summary section ---
        const Text(
          'Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (lecture.summaryText != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              lecture.summaryText!,
              style: const TextStyle(height: 1.5),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No summary generated yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          if (provider.summaryError != null) ...[
            Text(
              provider.summaryError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          AppButton(
            label: 'Generate Summary',
            isLoading: provider.isGeneratingSummary,
            onPressed: () => provider.generateSummary(widget.lectureId),
          ),
        ],

        const SizedBox(height: 24),

        // --- Topics section ---
        Text(
          'Topics (${lecture.topics.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (lecture.topics.isEmpty)
          const Text(
            'No topics were extracted from this lecture.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...lecture.topics.asMap().entries.map(
            (entry) => TopicTile(
              topic: entry.value,
              index: entry.key,
              lectureId: lecture.lectureId,
            ),
          ),

        const SizedBox(height: 24),

        // --- Quiz entry point ---
        AppButton(
          label: 'Generate Quiz',
          onPressed: lecture.topics.isEmpty
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuizGenerationScreen(lectureId: lecture.lectureId),
                  ),
                ),
        ),
      ],
    );
  }
}
