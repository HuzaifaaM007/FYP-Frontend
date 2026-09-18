import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationApiService {
  final _dio = ApiClient().dio;

  Future<List<AppNotification>> list() async {
    final response = await _dio.get('/notifications');
    return (response.data as List).map((item) => AppNotification.fromJson(item)).toList();
  }

  Future<void> markRead(String notificationId) async {
    await _dio.post('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}