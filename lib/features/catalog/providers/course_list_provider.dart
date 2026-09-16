import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/catalog_service.dart';
import 'subject_list_provider.dart'; // reuse CatalogLoadState

class CourseListProvider extends ChangeNotifier {
  final _service = CatalogApiService();

  CatalogLoadState state = CatalogLoadState.loading;
  String? errorMessage;
  List<Course> courses = [];

  Future<void> load(String subjectSlug) async {
    state = CatalogLoadState.loading;
    notifyListeners();
    try {
      courses = await _service.fetchCourses(subjectSlug: subjectSlug);
      state = CatalogLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load courses.';
      state = CatalogLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}