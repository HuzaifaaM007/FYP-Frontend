import '../../../core/network/api_client.dart';
import '../models/planner_item.dart';

class PlannerService {
  final _dio = ApiClient().dio;

  Future<List<PlannerItem>> listItems() async {
    final response = await _dio.get('/planner');
    return (response.data as List).map((item) => PlannerItem.fromJson(item)).toList();
  }

  Future<PlannerItem> createGoal({required String title, String? description, String? dueAt}) async {
    final response = await _dio.post('/planner/goals', data: {
      'item_type': 'goal', 'title': title, 'description': description, 'due_at': dueAt,
    });
    return PlannerItem.fromJson(response.data);
  }

  Future<PlannerItem> createSession({required String title, String? description, String? scheduledFor}) async {
    final response = await _dio.post('/planner/sessions', data: {
      'item_type': 'session', 'title': title, 'description': description, 'scheduled_for': scheduledFor,
    });
    return PlannerItem.fromJson(response.data);
  }

  Future<PlannerItem> createReminder({required String title, String? description, String? dueAt}) async {
    final response = await _dio.post('/planner/reminders', data: {
      'item_type': 'reminder', 'title': title, 'description': description, 'due_at': dueAt,
    });
    return PlannerItem.fromJson(response.data);
  }

  Future<PlannerItem> updateStatus(String plannerItemId, String status) async {
    final response = await _dio.patch('/planner/$plannerItemId', data: {'status': status});
    return PlannerItem.fromJson(response.data);
  }
}