import 'package:flutter/material.dart';
import '../models/lecture.dart';
import '../services/lecture_service.dart';

enum LectureListState { loading, loaded, error }

class LectureListProvider extends ChangeNotifier {
  final _service = LectureService();

  LectureListState state = LectureListState.loading;
  String? errorMessage;
  List<Lecture> lectures = [];

  bool isUploading = false;
  String? uploadError;

  Future<void> loadLectures() async {
    state = LectureListState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      lectures = await _service.listLectures();
      state = LectureListState.loaded;
    } catch (_) {
      errorMessage = 'Could not load your lectures. Pull down to try again.';
      state = LectureListState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<Lecture?> uploadLecture(String filePath, String fileName) async {
    isUploading = true;
    uploadError = null;
    notifyListeners();

    try {
      final lecture = await _service.uploadLecture(filePath, fileName);
      lectures.insert(0, lecture);
      return lecture;
    } catch (e) {
      uploadError = 'Upload failed. The file may be too large, an unsupported '
          'type, or the AI processing timed out — try again.';
      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}