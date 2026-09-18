class AppNotification {
  final String notificationId;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notification_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool,
      createdAt: json['created_at'] as String,
    );
  }
}