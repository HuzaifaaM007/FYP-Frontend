class Course {
  final String courseId;
  final String subjectId;
  final String title;
  final String description;
  final String level;
  final String sourceUrl;
  final String attribution;

  Course({
    required this.courseId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.level,
    required this.sourceUrl,
    required this.attribution,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      level: json['level'] as String,
      sourceUrl: json['source_url'] as String,
      attribution: json['attribution'] as String,
    );
  }
}