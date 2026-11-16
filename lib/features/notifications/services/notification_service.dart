import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationApiService {
  final _dio = ApiClient().dio;

  Future<List<AppNotification>> list() async {
    await syncDue();
    final response = await _dio.get('/notifications');
    return (response.data as List).map((item) => AppNotification.fromJson(item)).toList();
  }

  Future<int> unreadCount() async {
    await syncDue();
    final response = await _dio.get('/notifications/unread-count');
    return (response.data['unread_count'] as num).toInt();
  }

  /// Turns planner items whose time has passed into notifications (works without the backend worker).
  Future<void> syncDue() async {
    try {
      await _dio.post('/planner/process-due');
    } catch (_) {
      // Older backend or offline: the list still loads.
    }
  }

  Future<void> markRead(String notificationId) async {
    await _dio.post('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
