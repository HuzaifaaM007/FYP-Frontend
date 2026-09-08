import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/quiz_response.dart';
import '../models/submission.dart';

class QuizService {
  final _dio = ApiClient().dio;

  Future<GeneratedQuiz> generateQuizFromLecture(
    String lectureId, {
    int numMcq = 5,
    int numShort = 3,
  }) async {
    final response = await _dio.post(
      '/lectures/$lectureId/quiz',
      data: {'num_mcq': numMcq, 'num_short': numShort},
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return GeneratedQuiz.fromJson(response.data);
  }

  Future<GeneratedQuiz> generateQuizFromLesson(
    String lessonId, {
    int numMcq = 5,
    int numShort = 3,
  }) async {
    final response = await _dio.post(
      '/catalog/lessons/$lessonId/quiz',
      data: {'num_mcq': numMcq, 'num_short': numShort},
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return GeneratedQuiz.fromJson(response.data);
  }

  Future<QuizSubmission> submitQuiz(String quizId, Map<String, String> answersByQuestionId) async {
    final response = await _dio.post(
      '/lectures/quizzes/$quizId/submit',
      data: {
        'answers': answersByQuestionId.entries
            .map((e) => {'question_id': e.key, 'answer': e.value})
            .toList(),
      },
      // Short-answer grading runs semantic similarity via RunPod per
      // question — give this room on quizzes with several short answers.
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return QuizSubmission.fromJson(response.data);
  }
}