import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../models/course_video.dart';
import '../providers/course_detail_provider.dart';
import '../providers/subject_list_provider.dart'; // for CatalogLoadState
import 'lesson_detail_screen.dart';
import 'video_player_screen.dart';

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
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.courseTitle),
            bottom: TabBar(
              indicatorColor: AppColors.textPrimary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                const Tab(text: 'Lessons'),
                Consumer<CourseDetailProvider>(
                  builder: (_, p, __) => Tab(text: p.videos.isEmpty ? 'Videos' : 'Videos (${p.videos.length})'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _LessonsTab(courseId: widget.courseId),
              _VideosTab(courseId: widget.courseId),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonsTab extends StatelessWidget {
  final String courseId;
  const _LessonsTab({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailProvider>(
      builder: (context, provider, _) {
        if (provider.state == CatalogLoadState.loading) return const LoadingView();
        if (provider.state == CatalogLoadState.error) {
          return ErrorView(message: provider.errorMessage ?? 'Something went wrong.', onRetry: () => provider.load(courseId));
        }
        if (provider.lessons.isEmpty) {
          return const Center(child: Text('No lessons in this course yet.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => provider.load(courseId),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.lessons.length,
            itemBuilder: (context, index) {
              final lesson = provider.lessons[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.surfaceElevated, child: Text('${index + 1}')),
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
          ),
        );
      },
    );
  }
}

class _VideosTab extends StatelessWidget {
  final String courseId;
  const _VideosTab({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailProvider>(
      builder: (context, provider, _) {
        if (provider.videosLoading && provider.videos.isEmpty) return const LoadingView();
        if (provider.videosError != null) {
          return ErrorView(message: provider.videosError!, onRetry: () => provider.loadVideos(courseId));
        }
        if (provider.videos.isEmpty) {
          return const Center(child: Text('No videos in this course yet.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadVideos(courseId),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.videos.length,
            itemBuilder: (context, index) => _VideoTile(video: provider.videos[index]),
          ),
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  final CourseVideo video;
  const _VideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoId: video.videoId, title: video.title)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 128,
              height: 76,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.surfaceElevated),
                  if (video.thumbnailUrl != null)
                    Image.network(video.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  const Center(child: Icon(Icons.play_circle_fill, size: 32, color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (video.durationLabel != null) video.durationLabel!,
                        if (video.hasTranscript) 'Transcript',
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
