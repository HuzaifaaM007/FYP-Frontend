import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/comment.dart';
import '../services/discussion_service.dart';
import '../widgets/discussion_section.dart';
import 'discussion_topic_screen.dart';
import 'new_topic_screen.dart';

/// "Discussions" tab: a space where students talk to each other about any topic.
class DiscussionListScreen extends StatefulWidget {
  const DiscussionListScreen({super.key});

  @override
  State<DiscussionListScreen> createState() => _DiscussionListScreenState();
}

class _DiscussionListScreenState extends State<DiscussionListScreen> {
  final _service = DiscussionService();
  final _search = TextEditingController();
  List<DiscussionTopic> _topics = [];
  List<String> _tags = [];
  String? _tag;
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  LiveFeed? _live;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _live = _service.openLive('discussions', 'all');
    _sub = _live!.events.listen((e) {
      if (e['type'] == 'topic_added' || e['type'] == 'topic_deleted') _load(silent: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    _live?.close();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.listTopics(q: _search.text.trim(), tag: _tag);
      if (!mounted) return;
      setState(() { _topics = result.topics; _tags = result.tags; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load discussions.'; });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(silent: true));
  }

  Future<void> _newTopic() async {
    final created = await Navigator.push<DiscussionTopic>(context, MaterialPageRoute(builder: (_) => const NewTopicScreen()));
    if (created != null && mounted) {
      setState(() => _topics.insert(0, created));
      _open(created);
    }
  }

  Future<void> _open(DiscussionTopic topic) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DiscussionTopicScreen(topicId: topic.topicId)));
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTopic,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New discussion'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search discussions',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () { _search.clear(); _load(silent: true); }),
              ),
            ),
          ),
          if (_tags.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _chip('All', _tag == null, () { setState(() => _tag = null); _load(silent: true); }),
                  ..._tags.map((t) => _chip(t, _tag == t, () { setState(() => _tag = t); _load(silent: true); })),
                ],
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.forum_outlined, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('No discussions yet.\nAsk a question or share something with other students.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: _topics.length,
        itemBuilder: (_, i) => _TopicCard(topic: _topics[i], onTap: () => _open(_topics[i])),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final DiscussionTopic topic;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = topic;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.isPinned ? AppColors.accentOrange.withOpacity(0.6) : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (t.isPinned) ...[Icon(Icons.push_pin, size: 14, color: AppColors.accentOrange), const SizedBox(width: 4)],
                if (t.isClosed) ...[Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4)],
                Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Text(t.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35)),
              const SizedBox(height: 10),
              Row(children: [
                Avatar(author: t.author, radius: 10),
                const SizedBox(width: 6),
                Text(t.author.name, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text('· ${timeAgo(t.lastActivityAt ?? t.createdAt)}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                if (t.tag != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                    child: Text(t.tag!, style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                  ),
                Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${t.replyCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
