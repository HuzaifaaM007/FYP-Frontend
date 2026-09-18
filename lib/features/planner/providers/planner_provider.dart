import 'package:flutter/material.dart';
import '../models/planner_item.dart';
import '../services/planner_service.dart';

enum PlannerLoadState { loading, loaded, error }

class PlannerProvider extends ChangeNotifier {
  final _service = PlannerService();

  PlannerLoadState state = PlannerLoadState.loading;
  String? errorMessage;
  List<PlannerItem> items = [];

  Future<void> load() async {
    state = PlannerLoadState.loading;
    notifyListeners();
    try {
      items = await _service.listItems();
      state = PlannerLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load your planner.';
      state = PlannerLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> addGoal(String title, String? description, String? dueAt) async {
    final item = await _service.createGoal(title: title, description: description, dueAt: dueAt);
    items.insert(0, item);
    notifyListeners();
  }

  Future<void> addSession(String title, String? description, String? scheduledFor) async {
    final item = await _service.createSession(title: title, description: description, scheduledFor: scheduledFor);
    items.insert(0, item);
    notifyListeners();
  }

  Future<void> addReminder(String title, String? description, String? dueAt) async {
    final item = await _service.createReminder(title: title, description: description, dueAt: dueAt);
    items.insert(0, item);
    notifyListeners();
  }

  Future<void> toggleComplete(PlannerItem item) async {
    final newStatus = item.isCompleted ? 'pending' : 'completed';
    final updated = await _service.updateStatus(item.plannerItemId, newStatus);
    final index = items.indexWhere((i) => i.plannerItemId == item.plannerItemId);
    if (index != -1) items[index] = updated;
    notifyListeners();
  }
}