import 'dart:typed_data';

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

  Future<Lecture?> uploadLecture(
    String? filePath, // null on web; bytes are used instead
    String fileName, {
    Uint8List? bytes,
  }) async {
    if (filePath == null && bytes == null) {
      uploadError = 'Could not read the selected file.';
      notifyListeners();
      return null;
    }

    isUploading = true;
    uploadError = null;
    notifyListeners();

    try {
      final lecture = await _service.uploadLecture(
        filePath,
        fileName,
        bytes: bytes,
      );
      lectures.insert(0, lecture);
      return lecture;
    } catch (e) {
      uploadError =
          'Upload failed. The file may be too large, an unsupported '
          'type, or the AI processing timed out — try again.';
      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLecture(String lectureId) async {
    try {
      await _service.deleteLecture(lectureId);
      lectures.removeWhere((l) => l.lectureId == lectureId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}