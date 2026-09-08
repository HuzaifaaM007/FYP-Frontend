import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/lectures/models/lecture_topic.dart';

class TopicTile extends StatelessWidget {
  final LectureTopic topic;
  final int index;

  const TopicTile({super.key, required this.topic, required this.index});

  Color _difficultyColor() {
    switch (topic.difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.accentGreen;
      case 'advanced':
        return AppColors.accentPink;
      default:
        return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(topic.summary, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    topic.difficulty,
                    style: TextStyle(color: _difficultyColor(), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}