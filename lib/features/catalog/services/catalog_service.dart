import '../../../core/network/api_client.dart';
import '../models/subject.dart';
import '../models/course.dart';
import '../models/course_video.dart';
import '../models/lesson.dart';

class CatalogApiService {
  final _dio = ApiClient().dio;

  Future<List<Subject>> fetchSubjects() async {
    final response = await _dio.get('/catalog/subjects');
    return (response.data as List).map((item) => Subject.fromJson(item)).toList();
  }

  Future<List<Course>> fetchCourses({String? subjectSlug}) async {
    final response = await _dio.get(
      '/catalog/courses',
      queryParameters: subjectSlug != null ? {'subject_slug': subjectSlug} : null,
    );
    return (response.data as List).map((item) => Course.fromJson(item)).toList();
  }

  Future<List<Lesson>> fetchCourseLessons(String courseId) async {
    final response = await _dio.get('/catalog/courses/$courseId/lessons');
    return (response.data as List).map((item) => Lesson.fromJson(item)).toList();
  }

  Future<Lesson> fetchLesson(String lessonId) async {
    final response = await _dio.get('/catalog/lessons/$lessonId');
    return Lesson.fromJson(response.data);
  }

  Future<List<CourseVideo>> fetchCourseVideos(String courseId) async {
    final response = await _dio.get('/catalog/courses/$courseId/videos');
    return (response.data as List).map((item) => CourseVideo.fromJson(item)).toList();
  }

  /// Full video including its transcript.
  Future<CourseVideo> fetchVideo(String videoId) async {
    final response = await _dio.get('/catalog/videos/$videoId');
    return CourseVideo.fromJson(response.data);
  }

  /// Tell the backend a lesson/video was finished. [kind] is 'lesson' or 'video'.
  /// Returns true when the backend accepted it as completed.
  Future<bool> reportProgress({required String kind, required String entityId, required double percent, int seconds = 0}) async {
    final response = await _dio.post('/me/progress', data: {
      'kind': kind,
      'entity_id': entityId,
      'percent': percent,
      'seconds': seconds,
    });
    return (response.data as Map)['completed'] == true;
  }
}
