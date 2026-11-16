
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/navigation/app_routes.dart';
import '../../features/notifications/services/notification_service.dart';

/// Bell icon for the app bar. Shows how many notifications are unread and checks again every 30 seconds.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  final _service = NotificationApiService();
  Timer? _timer;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final count = await _service.unreadCount();
      if (mounted && count != _unread) setState(() => _unread = count);
    } catch (_) {
      // A failed check just keeps the last number; the next check tries again.
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 99 ? '99+' : '$_unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () async {
        await Navigator.pushNamed(context, AppRoutes.notifications);
        _refresh(); // the count may have changed while the list was open
      },
    );
  }
}
