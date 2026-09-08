import 'lecture.dart';
import 'lecture_topic.dart';

class LectureDetail extends Lecture {
  final String? summaryText;
  final List<LectureTopic> topics;

  LectureDetail({
    required super.lectureId,
    required super.title,
    required super.fileType,
    required super.fileSize,
    required super.processingStatus,
    required super.createdAt,
    this.summaryText,
    required this.topics,
  });

  factory LectureDetail.fromJson(Map<String, dynamic> json) {
    return LectureDetail(
      lectureId: json['lecture_id'] as String,
      title: json['title'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      processingStatus: json['processing_status'] as String,
      createdAt: json['created_at'] as String,
      summaryText: json['summary_text'] as String?,
      topics: (json['topics'] as List).map((t) => LectureTopic.fromJson(t)).toList(),
    );
  }
}