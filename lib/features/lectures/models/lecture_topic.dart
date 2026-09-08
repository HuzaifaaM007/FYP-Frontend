class LectureTopic {
  final String topicId;
  final String title;
  final String summary;
  final String difficulty;
  final int orderIndex;
  final bool isUserEdited;

  LectureTopic({
    required this.topicId,
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.orderIndex,
    required this.isUserEdited,
  });

  factory LectureTopic.fromJson(Map<String, dynamic> json) {
    return LectureTopic(
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      difficulty: json['difficulty'] as String,
      orderIndex: json['order_index'] as int,
      isUserEdited: json['is_user_edited'] as bool,
    );
  }
}