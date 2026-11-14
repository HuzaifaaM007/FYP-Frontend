import 'package:flutter/material.dart';
import '../models/course_video.dart';
import '../models/lesson.dart';
import '../services/catalog_service.dart';
import 'subject_list_provider.dart'; // reuse CatalogLoadState

class CourseDetailProvider extends ChangeNotifier {
  final _service = CatalogApiService();

  CatalogLoadState state = CatalogLoadState.loading;
  String? errorMessage;
  List<Lesson> lessons = [];

  // Videos load on their own so a problem there never hides the lessons.
  List<CourseVideo> videos = [];
  bool videosLoading = true;
  String? videosError;

  Future<void> load(String courseId) async {
    state = CatalogLoadState.loading;
    errorMessage = null;
    notifyListeners();
    await Future.wait([_loadLessons(courseId), loadVideos(courseId)]);
  }

  Future<void> _loadLessons(String courseId) async {
    try {
      lessons = await _service.fetchCourseLessons(courseId);
      state = CatalogLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load lessons.';
      state = CatalogLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadVideos(String courseId) async {
    videosLoading = true;
    videosError = null;
    notifyListeners();
    try {
      videos = await _service.fetchCourseVideos(courseId);
    } catch (_) {
      videosError = 'Could not load videos.';
    } finally {
      videosLoading = false;
      notifyListeners();
    }
  }
}
