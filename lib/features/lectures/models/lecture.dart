class Lecture {
  final String lectureId;
  final String title;
  final String fileType;
  final int fileSize;
  final String processingStatus;
  final String createdAt;

  Lecture({
    required this.lectureId,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.processingStatus,
    required this.createdAt,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      lectureId: json['lecture_id'] as String,
      title: json['title'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      processingStatus: json['processing_status'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  bool get isReady => processingStatus == 'topics_ready';
  bool get isFailed => processingStatus == 'failed';
}