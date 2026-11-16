import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Phone notifications for planner reminders, sessions and goals.
/// They are scheduled on the device itself, so they fire even when the app is closed
/// and even when the backend is offline.
class ReminderNotifications {
  ReminderNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      // Use the phone's own offset so 9:00 means 9:00 local time.
      final offset = DateTime.now().timeZoneOffset;
      tz.setLocalLocation(tz.getLocation(_zoneNameFor(offset)));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); // Android 13+ asks the user once
    _ready = true;
  }

  static String _zoneNameFor(Duration offset) {
    final hours = offset.inMinutes / 60;
    if (hours == 5) return 'Asia/Karachi';
    if (hours == 5.5) return 'Asia/Kolkata';
    if (hours == 4) return 'Asia/Dubai';
    if (hours == 0) return 'UTC';
    if (hours == 1) return 'Europe/Berlin';
    if (hours == 8) return 'Asia/Shanghai';
    if (hours == -5) return 'America/New_York';
    return 'UTC';
  }

  static int _id(String plannerItemId) => plannerItemId.hashCode & 0x7fffffff;

  /// Schedule (or re-schedule) a notification. Past times are ignored.
  static Future<void> schedule({
    required String plannerItemId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready || kIsWeb) return;
    if (!when.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: _id(plannerItemId),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'planner_reminders',
            'Planner reminders',
            channelDescription: 'Reminders, study sessions and goal deadlines from your planner',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact = no special "exact alarm" permission needed; fires within a few minutes of the time.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Notifications are a convenience; never let them break the planner.
    }
  }

  static Future<void> cancel(String plannerItemId) async {
    if (!_ready || kIsWeb) return;
    try {
      await _plugin.cancel(id: _id(plannerItemId));
    } catch (_) {}
  }
}