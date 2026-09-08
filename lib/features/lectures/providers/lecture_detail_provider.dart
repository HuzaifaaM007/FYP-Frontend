import 'package:flutter/material.dart';
import '../models/lecture_detail.dart';
import '../services/lecture_service.dart';

enum LectureDetailState { loading, loaded, error }

class LectureDetailProvider extends ChangeNotifier {
  final _service = LectureService();

  LectureDetailState state = LectureDetailState.loading;
  String? errorMessage;
  LectureDetail? lecture;

  bool isGeneratingSummary = false;
  String? summaryError;

  Future<void> load(String lectureId) async {
    state = LectureDetailState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      lecture = await _service.getLecture(lectureId);
      state = LectureDetailState.loaded;
    } catch (_) {
      errorMessage = 'Could not load this lecture.';
      state = LectureDetailState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> generateSummary(String lectureId) async {
    isGeneratingSummary = true;
    summaryError = null;
    notifyListeners();

    try {
      lecture = await _service.generateSummary(lectureId);
    } catch (_) {
      summaryError = 'Could not generate a summary right now. Please try again.';
    } finally {
      isGeneratingSummary = false;
      notifyListeners();
    }
  }
}