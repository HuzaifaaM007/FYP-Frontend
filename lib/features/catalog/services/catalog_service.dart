import '../../../core/network/api_client.dart';
import '../models/subject.dart';
import '../models/course.dart';
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
}