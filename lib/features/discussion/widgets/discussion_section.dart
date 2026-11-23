import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../models/comment.dart';
import '../services/discussion_service.dart';
import 'package:dio/dio.dart';

/// Comments for one course / lesson / video / discussion topic, with live updates.
/// Drop it at the bottom of a screen:  DiscussionSection(targetType: 'lesson', targetId: lesson.lessonId)
/// Set [embedded] = false when it fills its own screen (it then uses its own scroll view).
class DiscussionSection extends StatefulWidget {
  final String targetType;
  final String targetId;
  final bool embedded;
  final String title;
  final bool readOnly;

  const DiscussionSection({
    super.key,
    required this.targetType,
    required this.targetId,
    this.embedded = true,
    this.title = 'Discussion',
    this.readOnly = false,
  });

  @override
  State<DiscussionSection> createState() => _DiscussionSectionState();
}

class _DiscussionSectionState extends State<DiscussionSection> {
  final _service = DiscussionService();
  final _input = TextEditingController();
  final _focus = FocusNode();

  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Comment? _replyTo;
  LiveFeed? _live;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _live = _service.openLive(widget.targetType, widget.targetId);
    _sub = _live!.events.listen(_onLiveEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _live?.close();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _service.listComments(
        widget.targetType,
        widget.targetId,
      );
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the discussion.';
      });
    }
  }

  // ---- live events from other students
  void _onLiveEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    switch (event['type']) {
      case 'comment_added':
        final c = Comment.fromJson(
          (event['comment'] as Map).cast<String, dynamic>(),
        );
        if (_find(c.commentId) != null) return; // we posted it ourselves
        setState(() {
          if (c.parentId == null) {
            _comments.insert(0, c);
          } else {
            final parent = _find(c.parentId!);
            if (parent != null) parent.replies.add(c);
          }
        });
        break;
      case 'comment_deleted':
        final id = event['comment_id'] as String;
        setState(() => _removeOrMarkDeleted(id));
        break;
      case 'comment_liked':
        final c = _find(event['comment_id'] as String);
        if (c != null)
          setState(() => c.likeCount = (event['like_count'] as num).toInt());
        break;
    }
  }

  Comment? _find(String id) {
    for (final c in _comments) {
      if (c.commentId == id) return c;
      for (final r in c.replies) {
        if (r.commentId == id) return r;
      }
    }
    return null;
  }

  void _removeOrMarkDeleted(String id) {
    for (final c in _comments) {
      c.replies.removeWhere((r) => r.commentId == id);
    }
    final idx = _comments.indexWhere((c) => c.commentId == id);
    if (idx == -1) return;
    if (_comments[idx].replies.isEmpty) {
      _comments.removeAt(idx);
    } else {
      _comments[idx].isDeleted = true;
      _comments[idx].body = '[deleted]';
    }
  }

  // ---- actions
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await _service.addComment(
        widget.targetType,
        widget.targetId,
        text,
        parentId: _replyTo?.commentId,
      );
      if (!mounted) return;
      setState(() {
        if (created.parentId == null) {
          _comments.insert(0, created);
        } else {
          _find(created.parentId!)?.replies.add(created);
        }
        _input.clear();
        _replyTo = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post your comment. ${_reason(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _reason(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      if (e.response?.statusCode != null) {
        return '(error ${e.response!.statusCode})';
      }
      return '(${e.type.name})';
    }
    return '($e)';
  }

  Future<void> _toggleLike(Comment c) async {
    final wasLiked = c.likedByMe;
    setState(() {
      c.likedByMe = !wasLiked;
      c.likeCount += wasLiked ? -1 : 1;
    });
    try {
      final result = await _service.toggleLike(c.commentId);
      if (mounted)
        setState(() {
          c.likedByMe = result.liked;
          c.likeCount = result.likeCount;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          c.likedByMe = wasLiked;
          c.likeCount += wasLiked ? 1 : -1;
        });
    }
  }

  Future<void> _delete(Comment c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete comment?'),
        content: Text(c.body, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.deleteComment(c.commentId);
      if (mounted) setState(() => _removeOrMarkDeleted(c.commentId));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not delete.')));
    }
  }

  void _startReply(Comment c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }

  // ---- UI
  @override
  Widget build(BuildContext context) {
    final total = _comments.fold<int>(
      0,
      (n, c) => n + (c.isDeleted ? 0 : 1) + c.replies.length,
    );
    final header = Row(
      children: [
        Icon(Icons.forum_outlined, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 8),
        Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        if (!_loading)
          Text('$total', style: TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Live',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );

    final body = <Widget>[
      header,
      const SizedBox(height: 12),
      if (!widget.readOnly) _composer(),
      const SizedBox(height: 12),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        )
      else if (_comments.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              'No comments yet. Start the discussion!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        )
      else
        ..._comments.map(
          (c) => _CommentTile(
            comment: c,
            onLike: _toggleLike,
            onReply: widget.readOnly ? null : _startReply,
            onDelete: _delete,
          ),
        ),
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: body,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: body),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyTo!.author.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _replyTo = null),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  // Keyboard's Enter key now posts the comment.
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) =>
                      setState(() {}), // enables/disables the send button
                  decoration: InputDecoration(
                    hintText: _replyTo == null
                        ? 'Write a reply…'
                        : 'Reply to ${_replyTo!.author.name}…',
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Big round send button
              Material(
                color: _input.text.trim().isEmpty
                    ? AppColors.surfaceElevated
                    : AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending || _input.text.trim().isEmpty ? null : _send,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: _input.text.trim().isEmpty
                                  ? AppColors.textDisabled
                                  : AppColors.onPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final Future<void> Function(Comment) onLike;
  final void Function(Comment)? onReply;
  final Future<void> Function(Comment) onDelete;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = comment;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 36 : 0, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(author: c.author, radius: isReply ? 14 : 18),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.author.isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            timeAgo(c.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.body,
                        style: TextStyle(
                          height: 1.4,
                          color: c.isDeleted
                              ? AppColors.textDisabled
                              : AppColors.textPrimary,
                          fontStyle: c.isDeleted ? FontStyle.italic : null,
                        ),
                      ),
                      if (!c.isDeleted) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _action(
                              icon: c.likedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: c.likeCount == 0
                                  ? 'Like'
                                  : '${c.likeCount}',
                              color: c.likedByMe
                                  ? AppColors.accentPink
                                  : AppColors.textSecondary,
                              onTap: () => onLike(c),
                            ),
                            if (onReply != null && !isReply) ...[
                              const SizedBox(width: 16),
                              _action(
                                icon: Icons.reply,
                                label: 'Reply',
                                color: AppColors.textSecondary,
                                onTap: () => onReply!(c),
                              ),
                            ],
                            if (c.canDelete) ...[
                              const SizedBox(width: 16),
                              _action(
                                icon: Icons.delete_outline,
                                label: 'Delete',
                                color: AppColors.textSecondary,
                                onTap: () => onDelete(c),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          ...c.replies.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _CommentTile(
                comment: r,
                onLike: onLike,
                onReply: onReply,
                onDelete: onDelete,
                isReply: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Small avatar used by comments and topics (picture if the student uploaded one, else initial).
class Avatar extends StatelessWidget {
  final CommentAuthor author;
  final double radius;
  const Avatar({super.key, required this.author, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final url = author.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: url != null
          ? NetworkImage('${Env.apiBaseUrl}$url')
          : null,
      child: url == null
          ? Text(
              author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
