import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/lectures/models/lecture.dart';

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback onTap;

  const LectureCard({super.key, required this.lecture, required this.onTap});

  Color _statusColor() {
    switch (lecture.processingStatus) {
      case 'topics_ready':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel() {
    switch (lecture.processingStatus) {
      case 'topics_ready':
        return 'Ready';
      case 'failed':
        return 'Failed';
      case 'parsed':
        return 'Processing...';
      default:
        return 'Uploaded';
    }
  }

  IconData _fileIcon() {
    switch (lecture.fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: lecture.isReady ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(_fileIcon(), color: AppColors.textSecondary),
        title: Text(lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _statusColor(), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(_statusLabel(), style: TextStyle(color: _statusColor(), fontSize: 12)),
          ],
        ),
        trailing: lecture.isReady ? Icon(Icons.chevron_right, color: AppColors.textSecondary) : null,
      ),
    );
  }
}