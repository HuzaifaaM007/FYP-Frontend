import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/course_list_provider.dart';
import '../providers/subject_list_provider.dart'; // for CatalogLoadState
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  final String subjectSlug;
  final String subjectName;

  const CourseListScreen({super.key, required this.subjectSlug, required this.subjectName});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  late final CourseListProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CourseListProvider();
    _provider.load(widget.subjectSlug);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.subjectName)),
        body: Consumer<CourseListProvider>(
          builder: (context, provider, _) {
            if (provider.state == CatalogLoadState.loading) return const LoadingView();
            if (provider.state == CatalogLoadState.error) {
              return ErrorView(
                message: provider.errorMessage ?? 'Something went wrong.',
                onRetry: () => provider.load(widget.subjectSlug),
              );
            }
            if (provider.courses.isEmpty) {
              return Center(child: Text('No courses in this subject yet.', style: TextStyle(color: AppColors.textSecondary)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.courses.length,
              itemBuilder: (context, index) {
                final course = provider.courses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.courseId, courseTitle: course.title)),
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