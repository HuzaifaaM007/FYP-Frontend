import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/catalog_service.dart';

enum CatalogLoadState { loading, loaded, error }

class SubjectListProvider extends ChangeNotifier {
  final _service = CatalogApiService();

  CatalogLoadState state = CatalogLoadState.loading;
  String? errorMessage;
  List<Subject> subjects = [];

  Future<void> load() async {
    state = CatalogLoadState.loading;
    notifyListeners();
    try {
      subjects = await _service.fetchSubjects();
      state = CatalogLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load subjects.';
      state = CatalogLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}