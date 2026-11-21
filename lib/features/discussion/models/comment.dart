class CommentAuthor {
  final String userId;
  final String name;
  final bool isAdmin;
  final String? avatarUrl; // relative path, prefix with Env.apiBaseUrl

  const CommentAuthor({required this.userId, required this.name, required this.isAdmin, this.avatarUrl});

  factory CommentAuthor.fromJson(Map<String, dynamic> json) => CommentAuthor(
        userId: json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Student',
        isAdmin: json['is_admin'] == true,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class Comment {
  final String commentId;
  final String? parentId;
  String body;
  bool isDeleted;
  final CommentAuthor author;
  final DateTime? createdAt;
  int likeCount;
  bool likedByMe;
  final bool canDelete;
  final List<Comment> replies;

  Comment({
    required this.commentId,
    required this.parentId,
    required this.body,
    required this.isDeleted,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
    required this.canDelete,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        commentId: json['comment_id'] as String,
        parentId: json['parent_id'] as String?,
        body: json['body'] as String? ?? '',
        isDeleted: json['is_deleted'] == true,
        author: CommentAuthor.fromJson((json['author'] as Map?)?.cast<String, dynamic>() ?? const {}),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
        likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
        likedByMe: json['liked_by_me'] == true,
        canDelete: json['can_delete'] == true,
        replies: ((json['replies'] as List?) ?? const []).map((e) => Comment.fromJson((e as Map).cast<String, dynamic>())).toList(),
      );
}

class DiscussionTopic {
  final String topicId;
  final String title;
  final String body;
  final String? tag;
  final bool isPinned;
  final bool isClosed;
  final CommentAuthor author;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  int replyCount;

  DiscussionTopic({
    required this.topicId,
    required this.title,
    required this.body,
    required this.tag,
    required this.isPinned,
    required this.isClosed,
    required this.author,
    required this.createdAt,
    required this.lastActivityAt,
    required this.replyCount,
  });

  factory DiscussionTopic.fromJson(Map<String, dynamic> json) => DiscussionTopic(
        topicId: json['topic_id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        tag: json['tag'] as String?,
        isPinned: json['is_pinned'] == true,
        isClosed: json['is_closed'] == true,
        author: CommentAuthor.fromJson((json['author'] as Map?)?.cast<String, dynamic>() ?? const {}),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
        lastActivityAt: DateTime.tryParse(json['last_activity_at'] as String? ?? '')?.toLocal(),
        replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      );
}

String timeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return '${time.day}/${time.month}/${time.year}';
}
