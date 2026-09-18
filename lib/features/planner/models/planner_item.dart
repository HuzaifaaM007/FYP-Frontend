class PlannerItem {
  final String plannerItemId;
  final String itemType; // "goal" | "session" | "reminder"
  final String title;
  final String? description;
  final String? dueAt;
  final String? scheduledFor;
  final String status;
  final String createdAt;

  PlannerItem({
    required this.plannerItemId,
    required this.itemType,
    required this.title,
    this.description,
    this.dueAt,
    this.scheduledFor,
    required this.status,
    required this.createdAt,
  });

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    return PlannerItem(
      plannerItemId: json['planner_item_id'] as String,
      itemType: json['item_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueAt: json['due_at'] as String?,
      scheduledFor: json['scheduled_for'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  bool get isCompleted => status == 'completed';
}