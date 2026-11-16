import 'package:flutter/material.dart';
import '../../../core/notifications/reminder_notifications.dart';
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
      // Make sure every pending item with a future time has a phone notification
      // (covers items created on another device or before this update).
      for (final item in items) {
        _syncNotification(item);
      }
    } catch (_) {
      errorMessage = 'Could not load your planner.';
      state = PlannerLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Reload without showing the full-screen spinner (used by pull-to-refresh).
  Future<void> refresh() async {
    try {
      items = await _service.listItems();
      state = PlannerLoadState.loaded;
    } catch (_) {
      // Keep what we have.
    }
    notifyListeners();
  }

  Future<void> addGoal(String title, String? description, String? dueAt) async {
    final item = await _service.createGoal(title: title, description: description, dueAt: dueAt);
    items.insert(0, item);
    _syncNotification(item);
    notifyListeners();
  }

  Future<void> addSession(String title, String? description, String? scheduledFor) async {
    final item = await _service.createSession(title: title, description: description, scheduledFor: scheduledFor);
    items.insert(0, item);
    _syncNotification(item);
    notifyListeners();
  }

  Future<void> addReminder(String title, String? description, String? dueAt) async {
    final item = await _service.createReminder(title: title, description: description, dueAt: dueAt);
    items.insert(0, item);
    _syncNotification(item);
    notifyListeners();
  }

  Future<void> toggleComplete(PlannerItem item) async {
    final newStatus = item.isCompleted ? 'pending' : 'completed';
    final updated = await _service.updateStatus(item.plannerItemId, newStatus);
    final index = items.indexWhere((i) => i.plannerItemId == item.plannerItemId);
    if (index != -1) items[index] = updated;
    _syncNotification(updated);
    notifyListeners();
  }

  Future<void> remove(PlannerItem item) async {
    await _service.deleteItem(item.plannerItemId);
    items.removeWhere((i) => i.plannerItemId == item.plannerItemId);
    ReminderNotifications.cancel(item.plannerItemId);
    notifyListeners();
  }

  static DateTime? _time(PlannerItem item) {
    final raw = item.dueAt ?? item.scheduledFor;
    if (raw == null || raw.isEmpty) return null;
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
    return DateTime.tryParse(hasZone ? raw : '${raw}Z')?.toLocal();
  }

  void _syncNotification(PlannerItem item) {
    final when = _time(item);
    if (item.isCompleted || when == null) {
      ReminderNotifications.cancel(item.plannerItemId);
      return;
    }
    final label = switch (item.itemType) {
      'session' => 'Study session',
      'goal' => 'Goal due',
      _ => 'Reminder',
    };
    ReminderNotifications.schedule(
      plannerItemId: item.plannerItemId,
      title: '$label: ${item.title}',
      body: item.description?.isNotEmpty == true ? item.description! : 'Open Study Sensei to get started.',
      when: when,
    );
  }
}
