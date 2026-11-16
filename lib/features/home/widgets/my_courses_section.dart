import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/screens/course_detail_screen.dart';
import '../models/activity.dart';

/// Courses the student has started (finished a lesson or video, or took a quiz).
class MyCoursesSection extends StatelessWidget {
  final List<EnrolledCourse> courses;
  const MyCoursesSection({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'You have not started a course yet. Finish a lesson from the Catalog tab and it will show up here.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...courses.take(6).toList().asMap().entries.map((e) {
            final c = e.value;
            final accent = AppColors.accentPalette[e.key % AppColors.accentPalette.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: c.courseId, courseTitle: c.title)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Text('${(c.progress * 100).round()}%', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (c.subject.isNotEmpty)
                        Text(c.subject, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${c.lessonsRead}/${c.lessonsTotal} lessons finished'
                        '${c.videosTotal > 0 ? ' · ${c.videosWatched}/${c.videosTotal} videos' : ''}'
                        '${c.avgScore != null ? ' · quiz avg ${c.avgScore!.toStringAsFixed(0)}%' : ''}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
