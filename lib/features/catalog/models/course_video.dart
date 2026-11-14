class CourseVideo {
  final String videoId;
  final String title;
  final String? description;
  final String provider; // youtube | vimeo | direct
  final String? externalId;
  final String sourceUrl;
  final String embedUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? attribution;
  final bool hasTranscript;
  final String? transcript;
  final String? transcriptFormat; // vtt | text

  CourseVideo({
    required this.videoId,
    required this.title,
    required this.provider,
    required this.sourceUrl,
    required this.embedUrl,
    this.description,
    this.externalId,
    this.thumbnailUrl,
    this.durationSeconds,
    this.attribution,
    this.hasTranscript = false,
    this.transcript,
    this.transcriptFormat,
  });

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    return CourseVideo(
      videoId: json['video_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      provider: json['provider'] as String,
      externalId: json['external_id'] as String?,
      sourceUrl: json['source_url'] as String,
      embedUrl: json['embed_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      attribution: json['attribution'] as String?,
      hasTranscript: (json['has_transcript'] as bool?) ?? (json['transcript'] != null),
      transcript: json['transcript'] as String?,
      transcriptFormat: json['transcript_format'] as String?,
    );
  }

  String? get durationLabel {
    final total = durationSeconds;
    if (total == null) return null;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }
}
