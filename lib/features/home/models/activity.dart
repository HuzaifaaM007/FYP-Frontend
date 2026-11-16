class ActivityDay {
  final DateTime date;
  final int lessons;
  final int videos;
  const ActivityDay({required this.date, required this.lessons, required this.videos});

  factory ActivityDay.fromJson(Map<String, dynamic> json) => ActivityDay(
        date: DateTime.parse(json['date'] as String),
        lessons: (json['lessons'] as num?)?.toInt() ?? 0,
        videos: (json['videos'] as num?)?.toInt() ?? 0,
      );
}

class EnrolledCourse {
  final String courseId;
  final String title;
  final String subject;
  final int lessonsTotal;
  final int lessonsRead;
  final int videosTotal;
  final int videosWatched;
  final int quizAttempts;
  final double? avgScore;
  final double progress; // 0..1, lessons read / lessons total

  const EnrolledCourse({
    required this.courseId,
    required this.title,
    required this.subject,
    required this.lessonsTotal,
    required this.lessonsRead,
    required this.videosTotal,
    required this.videosWatched,
    required this.quizAttempts,
    required this.avgScore,
    required this.progress,
  });

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) => EnrolledCourse(
        courseId: json['course_id'] as String,
        title: json['title'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        lessonsTotal: (json['lessons_total'] as num?)?.toInt() ?? 0,
        lessonsRead: (json['lessons_read'] as num?)?.toInt() ?? 0,
        videosTotal: (json['videos_total'] as num?)?.toInt() ?? 0,
        videosWatched: (json['videos_watched'] as num?)?.toInt() ?? 0,
        quizAttempts: (json['quiz_attempts'] as num?)?.toInt() ?? 0,
        avgScore: (json['avg_score'] as num?)?.toDouble(),
        progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      );
}

class StudentActivity {
  final int days;
  final int lessonsRead;
  final int videosWatched;
  final int activeDays;
  final List<ActivityDay> series;
  final List<EnrolledCourse> courses;

  const StudentActivity({
    required this.days,
    required this.lessonsRead,
    required this.videosWatched,
    required this.activeDays,
    required this.series,
    required this.courses,
  });

  factory StudentActivity.fromJson(Map<String, dynamic> json) => StudentActivity(
        days: (json['days'] as num?)?.toInt() ?? 14,
        lessonsRead: (json['lessons_read'] as num?)?.toInt() ?? 0,
        videosWatched: (json['videos_watched'] as num?)?.toInt() ?? 0,
        activeDays: (json['active_days'] as num?)?.toInt() ?? 0,
        series: ((json['series'] as List?) ?? const [])
            .map((e) => ActivityDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        courses: ((json['courses'] as List?) ?? const [])
            .map((e) => EnrolledCourse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
