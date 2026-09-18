import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

enum NotificationLoadState { loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationApiService();

  NotificationLoadState state = NotificationLoadState.loading;
  String? errorMessage;
  List<AppNotification> notifications = [];

  Future<void> load() async {
    state = NotificationLoadState.loading;
    notifyListeners();
    try {
      notifications = await _service.list();
      state = NotificationLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load notifications.';
      state = NotificationLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markRead(String notificationId) async {
    await _service.markRead(notificationId);
    final index = notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1) {
      final old = notifications[index];
      notifications[index] = AppNotification(
        notificationId: old.notificationId, title: old.title, body: old.body,
        notificationType: old.notificationType, isRead: true, createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    await load();
  }
}