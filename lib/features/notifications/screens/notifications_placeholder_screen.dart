import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/notification_provider.dart';

class NotificationsPlaceholderScreen extends StatefulWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  State<NotificationsPlaceholderScreen> createState() => _NotificationsPlaceholderScreenState();
}

class _NotificationsPlaceholderScreenState extends State<NotificationsPlaceholderScreen> {
  late final NotificationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NotificationProvider();
    _provider.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Notifications'),
              actions: [
                if (provider.notifications.any((n) => !n.isRead))
                  TextButton(onPressed: provider.markAllRead, child: const Text('Mark all read')),
              ],
            ),
            body: _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.state == NotificationLoadState.loading) return const LoadingView();
    if (provider.state == NotificationLoadState.error) {
      return ErrorView(message: provider.errorMessage ?? 'Something went wrong.', onRetry: () => provider.load());
    }
    if (provider.notifications.isEmpty) {
      return const Center(child: Text('No notifications yet.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.surface : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead ? null : Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
          ),
          child: ListTile(
            title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(notification.body),
            trailing: notification.isRead
                ? null
                : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle)),
            onTap: () => provider.markRead(notification.notificationId),
          ),
        );
      },
    );
  }
}