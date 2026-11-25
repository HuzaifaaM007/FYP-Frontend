import '../../../core/network/api_client.dart';
import '../models/my_quiz.dart';
import '../models/quiz_response.dart';
import '../models/submission.dart';

class MyQuizDetail {
  final GeneratedQuiz quiz;
  final QuizSubmission? submission; // null if the student never submitted it
  MyQuizDetail(this.quiz, this.submission);
}

class MyQuizzesService {
  final _dio = ApiClient().dio;

  Future<List<MyQuizItem>> list() async {
    final response = await _dio.get('/me/quizzes');
    return (response.data as List).map((e) => MyQuizItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MyQuizDetail> detail(String quizId) async {
    final response = await _dio.get('/me/quizzes/$quizId');
    final data = response.data as Map<String, dynamic>;
    final sub = data['submission'];
    return MyQuizDetail(
      GeneratedQuiz.fromJson(data['quiz'] as Map<String, dynamic>),
      sub == null ? null : QuizSubmission.fromJson(sub as Map<String, dynamic>),
    );
  }
}
