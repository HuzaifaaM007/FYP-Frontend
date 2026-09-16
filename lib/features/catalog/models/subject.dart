class Subject {
  final String subjectId;
  final String slug;
  final String name;
  final String? description;

  Subject({required this.subjectId, required this.slug, required this.name, this.description});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}