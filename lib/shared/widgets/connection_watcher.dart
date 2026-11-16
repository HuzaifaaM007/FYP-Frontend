import 'package:flutter/material.dart';
import '../../core/network/session_events.dart';
import '../../core/theme/app_colors.dart';

/// Shows one "cannot reach the server" dialog when any request fails to connect.
/// Put it above MaterialApp and give it the same navigatorKey.
class ConnectionWatcher extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  const ConnectionWatcher({super.key, required this.navigatorKey, required this.child});

  @override
  State<ConnectionWatcher> createState() => _ConnectionWatcherState();
}

class _ConnectionWatcherState extends State<ConnectionWatcher> {
  bool _showing = false;
  DateTime? _lastShown;

  @override
  void initState() {
    super.initState();
    SessionEvents.connectionLost.addListener(_onLost);
  }

  @override
  void dispose() {
    SessionEvents.connectionLost.removeListener(_onLost);
    super.dispose();
  }

  Future<void> _onLost() async {
    final message = SessionEvents.connectionLost.value;
    if (message == null || _showing) return;
    // Several requests usually fail together; one dialog per 20 seconds is enough.
    if (_lastShown != null && DateTime.now().difference(_lastShown!) < const Duration(seconds: 20)) return;
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    _showing = true;
    _lastShown = DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: Icon(Icons.wifi_off_rounded, color: AppColors.accentOrange, size: 36),
        title: const Text('Connection problem'),
        content: Text(message, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
    _showing = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
