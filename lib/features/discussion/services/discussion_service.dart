import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/comment.dart';

class DiscussionService {
  final _dio = ApiClient().dio;

  // ---- comments on a course / lesson / video / topic
  Future<List<Comment>> listComments(String targetType, String targetId) async {
    final response = await _dio.get('/comments', queryParameters: {'target_type': targetType, 'target_id': targetId});
    return ((response.data['comments'] as List?) ?? const []).map((e) => Comment.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<Comment> addComment(String targetType, String targetId, String body, {String? parentId}) async {
    final response = await _dio.post('/comments', data: {
      'target_type': targetType,
      'target_id': targetId,
      'body': body,
      if (parentId != null) 'parent_id': parentId,
    });
    return Comment.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteComment(String commentId) => _dio.delete('/comments/$commentId');

  Future<({bool liked, int likeCount})> toggleLike(String commentId) async {
    final response = await _dio.post('/comments/$commentId/like');
    return (liked: response.data['liked'] == true, likeCount: (response.data['like_count'] as num).toInt());
  }

  // ---- student discussions
  Future<({List<DiscussionTopic> topics, List<String> tags})> listTopics({String? q, String? tag}) async {
    final response = await _dio.get('/discussions', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
    });
    return (
      topics: ((response.data['topics'] as List?) ?? const []).map((e) => DiscussionTopic.fromJson((e as Map).cast<String, dynamic>())).toList(),
      tags: ((response.data['tags'] as List?) ?? const []).cast<String>(),
    );
  }

  Future<DiscussionTopic> createTopic(String title, String body, {String? tag}) async {
    final response = await _dio.post('/discussions', data: {'title': title, 'body': body, if (tag != null && tag.isNotEmpty) 'tag': tag});
    return DiscussionTopic.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<({DiscussionTopic topic, List<Comment> comments, bool canDelete})> getTopic(String topicId) async {
    final response = await _dio.get('/discussions/$topicId');
    final data = (response.data as Map).cast<String, dynamic>();
    return (
      topic: DiscussionTopic.fromJson(data),
      comments: ((data['comments'] as List?) ?? const []).map((e) => Comment.fromJson((e as Map).cast<String, dynamic>())).toList(),
      canDelete: data['can_delete'] == true,
    );
  }

  Future<void> deleteTopic(String topicId) => _dio.delete('/discussions/$topicId');

  // ---- live updates
  /// Opens a socket for one room. Events arrive as decoded JSON maps. Returns a handle to close it.
  LiveFeed openLive(String targetType, String targetId) => LiveFeed._(targetType, targetId);
}

/// Thin wrapper around the WebSocket: reconnects on failure, pings to stay alive.
class LiveFeed {
  final String targetType;
  final String targetId;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;
  Timer? _ping;
  bool _closed = false;
  int _attempt = 0;

  LiveFeed._(this.targetType, this.targetId) {
    _connect();
  }

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> _connect() async {
    if (_closed) return;
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return;
    final base = Env.apiBaseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/ws/comments?target_type=$targetType&target_id=$targetId&token=$token');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _ping?.cancel();
      _ping = Timer.periodic(const Duration(seconds: 25), (_) => channel.sink.add('ping'));
      channel.stream.listen(
        (raw) {
          _attempt = 0;
          try {
            final data = jsonDecode(raw as String);
            if (data is Map) _controller.add(data.cast<String, dynamic>());
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _attempt++;
    final delay = Duration(seconds: (2 * _attempt).clamp(2, 30));
    Future.delayed(delay, _connect);
  }

  void close() {
    _closed = true;
    _ping?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
