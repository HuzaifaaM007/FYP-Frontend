import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/catalog_service.dart';
import 'subject_list_provider.dart'; // reuse CatalogLoadState

class CourseDetailProvider extends ChangeNotifier {
  final _service = CatalogApiService();

  CatalogLoadState state = CatalogLoadState.loading;
  String? errorMessage;
  List<Lesson> lessons = [];

  Future<void> load(String courseId) async {
    state = CatalogLoadState.loading;
    notifyListeners();
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
}