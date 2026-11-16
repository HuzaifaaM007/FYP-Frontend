import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

/// Ask the backend whether the AI model is reachable before starting an AI action
/// (upload, summary, quiz, audio). Returns true when the action should go ahead.
///
/// Usage:  if (!await AiGate.check(context)) return;
class AiGate {
  AiGate._();

  static DateTime? _okUntil;

  static Future<bool> check(BuildContext context, {bool allowBasicMode = true}) async {
    // A recent "available" answer is reused for a minute so we do not ping before every tap.
    if (_okUntil != null && DateTime.now().isBefore(_okUntil!)) return true;

    Map<String, dynamic>? status;
    try {
      final response = await ApiClient().dio.get('/ai/status');
      status = Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      // Could not even ask (network down or old backend). Let the real request decide.
      return true;
    }
    if (status['available'] == true) {
      _okUntil = DateTime.now().add(const Duration(minutes: 1));
      return true;
    }
    if (!context.mounted) return false;

    final reason = (status['reason'] as String?) ?? 'The AI service is not responding.';
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: Icon(Icons.smart_toy_outlined, color: AppColors.accentPink, size: 36),
        title: const Text('AI service offline'),
        content: Text(
          '$reason\n\n'
          '${allowBasicMode ? 'You can continue in basic mode, but the result will be a simple automatic version instead of AI-generated content.' : 'Please try again in a few minutes.'}',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          if (allowBasicMode)
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Continue in basic mode')),
        ],
      ),
    );
    return proceed == true;
  }
}
