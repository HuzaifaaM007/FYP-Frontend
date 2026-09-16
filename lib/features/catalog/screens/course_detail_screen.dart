import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/course_detail_provider.dart';
import '../providers/subject_list_provider.dart'; // for CatalogLoadState
import 'lesson_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseDetailScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CourseDetailProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CourseDetailProvider();
    _provider.load(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: Consumer<CourseDetailProvider>(
          builder: (context, provider, _) {
            if (provider.state == CatalogLoadState.loading) return const LoadingView();
            if (provider.state == CatalogLoadState.error) {
              return ErrorView(
                message: provider.errorMessage ?? 'Something went wrong.',
                onRetry: () => provider.load(widget.courseId),
              );
            }
            if (provider.lessons.isEmpty) {
              return const Center(child: Text('No lessons in this course yet.', style: TextStyle(color: AppColors.textSecondary)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.lessons.length,
              itemBuilder: (context, index) {
                final lesson = provider.lessons[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceElevated,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${lesson.estimatedMinutes} min · ${lesson.difficulty}'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LessonDetailScreen(lessonId: lesson.lessonId)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}