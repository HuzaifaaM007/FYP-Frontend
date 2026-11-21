import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/comment.dart';
import '../services/discussion_service.dart';
import '../widgets/discussion_section.dart';

class DiscussionTopicScreen extends StatefulWidget {
  final String topicId;
  const DiscussionTopicScreen({super.key, required this.topicId});

  @override
  State<DiscussionTopicScreen> createState() => _DiscussionTopicScreenState();
}

class _DiscussionTopicScreenState extends State<DiscussionTopicScreen> {
  final _service = DiscussionService();
  DiscussionTopic? _topic;
  bool _canDelete = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getTopic(widget.topicId);
      if (!mounted) return;
      setState(() { _topic = result.topic; _canDelete = result.canDelete; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load this discussion.'; });
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete discussion?'),
        content: const Text('The post and all its comments will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.deleteTopic(widget.topicId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [if (_canDelete) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _content(),
    );
  }

  Widget _content() {
    final t = _topic!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Avatar(author: t.author, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.author.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(timeAgo(t.createdAt), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          if (t.tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
              child: Text(t.tag!, style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
            ),
        ]),
        const SizedBox(height: 14),
        Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 10),
        SelectableText(t.body, style: const TextStyle(fontSize: 15, height: 1.5)),
        if (t.isClosed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('This discussion was closed by an admin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        const SizedBox(height: 20),
        Divider(color: AppColors.border),
        const SizedBox(height: 12),
        DiscussionSection(targetType: 'topic', targetId: t.topicId, title: 'Replies', readOnly: t.isClosed),
      ],
    );
  }
}
