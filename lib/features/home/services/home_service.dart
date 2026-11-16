import '../../../core/network/api_client.dart';
import '../models/dashboard_stats.dart';
import '../models/weak_topic.dart';
import '../models/recommendation.dart';
import '../models/activity.dart';

class HomeService {
  final _dio = ApiClient().dio;

  Future<DashboardStats> fetchDashboard() async {
    final response = await _dio.get('/analytics/dashboard');
    return DashboardStats.fromJson(response.data);
  }

  Future<List<WeakTopic>> fetchWeakTopics() async {
    final response = await _dio.get('/analytics/weak-topics');
    return (response.data as List).map((item) => WeakTopic.fromJson(item)).toList();
  }

  Future<List<RecommendationItem>> fetchRecommendations() async {
    final response = await _dio.get('/recommendations/feed');
    return (response.data as List).map((item) => RecommendationItem.fromJson(item)).toList();
  }

  /// Lessons read / videos watched per day, plus the courses the student is working on.
  Future<StudentActivity> fetchActivity({int days = 14}) async {
    final response = await _dio.get('/me/activity', queryParameters: {
      'days': days,
      'tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
    });
    return StudentActivity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markRecommendationClicked(String recommendationId) async {
    await _dio.post('/recommendations/$recommendationId/click');
  }

  Future<void> dismissRecommendation(String recommendationId) async {
    await _dio.post('/recommendations/$recommendationId/dismiss');
  }
}
