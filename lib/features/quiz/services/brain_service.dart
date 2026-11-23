import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/brain.dart';

class BrainApiService {
  final _dio = ApiClient().dio;

  /// First time for a quiz the server asks the AI once 
  /// after that it is read from the database instantly.
  Future<Map<String, BrainWalkthrough>> forQuiz(String quizId) async {
    try {
      final response = await _dio.get('/brain/quizzes/$quizId');
      return parseQuizBrain((response.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) throw Exception(data['detail']);
      if (e.response == null) throw Exception('Could not reach the server.');
      throw Exception('Could not load the BRAIN breakdown.');
    }
  }
}
