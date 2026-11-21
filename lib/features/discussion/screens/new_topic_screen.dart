import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/comment.dart';
import '../services/discussion_service.dart';

class NewTopicScreen extends StatefulWidget {
  const NewTopicScreen({super.key});

  @override
  State<NewTopicScreen> createState() => _NewTopicScreenState();
}

class _NewTopicScreenState extends State<NewTopicScreen> {
  final _service = DiscussionService();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tag = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _suggestedTags = ['Question', 'Exam tips', 'Study group', 'Resources', 'General'];

  Future<void> _submit() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.length < 3) return setState(() => _error = 'Give your discussion a title (at least 3 characters).');
    if (body.isEmpty) return setState(() => _error = 'Write something for others to respond to.');
    setState(() { _saving = true; _error = null; });
    try {
      final topic = await _service.createTopic(title, body, tag: _tag.text.trim());
      if (mounted) Navigator.pop<DiscussionTopic>(context, topic);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not post the discussion. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New discussion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, maxLength: 200, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Title — e.g. How do you revise for calculus?')),
          const SizedBox(height: 10),
          TextField(controller: _body, minLines: 5, maxLines: 12, maxLength: 5000, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Explain your question or share your thoughts…')),
          const SizedBox(height: 10),
          TextField(controller: _tag, maxLength: 50, decoration: const InputDecoration(hintText: 'Tag (optional) — e.g. Physics')),
          Wrap(
            spacing: 8,
            children: _suggestedTags.map((t) => ActionChip(label: Text(t), onPressed: () => setState(() => _tag.text = t))).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          AppButton(label: 'Post discussion', isLoading: _saving, onPressed: _submit),
          const SizedBox(height: 8),
          Text('Be respectful. Admins can remove posts that break the rules.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
