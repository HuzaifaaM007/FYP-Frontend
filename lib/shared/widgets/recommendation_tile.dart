import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RecommendationTile extends StatelessWidget {
  final String title;
  final String reason;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const RecommendationTile({
    super.key,
    required this.title,
    required this.reason,
    required this.accentColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 8,
          decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(reason, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              tooltip: 'Not interested',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
