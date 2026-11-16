import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../features/lectures/models/lecture_topic.dart';
import 'audio_player_widget.dart';

class TopicTile extends StatefulWidget {
  final LectureTopic topic;
  final int index;
  final String lectureId;

  const TopicTile({super.key, required this.topic, required this.index, required this.lectureId});

  @override
  State<TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<TopicTile> {
  String? _audioUrl;
  bool _isGeneratingAudio = false;

  Color _difficultyColor() {
    switch (widget.topic.difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.accentGreen;
      case 'advanced':
        return AppColors.accentPink;
      default:
        return AppColors.accentBlue;
    }
  }

  Future<void> _generateAudio() async {
    setState(() => _isGeneratingAudio = true);
    try {
      final response = await ApiClient().dio.post(
        '/lectures/${widget.lectureId}/topics/${widget.topic.topicId}/audio',
        data: {},
      );
      final relativePath = response.data['file_path'] as String?;
      if (relativePath != null) {
        setState(() => _audioUrl = '${Env.apiBaseUrl}/${relativePath.replaceAll('\\', '/')}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio is still processing — try again shortly.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate audio for this topic.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
                child: Text('${widget.index + 1}', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.topic.summary, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _difficultyColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.topic.difficulty,
                        style: TextStyle(color: _difficultyColor(), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isGeneratingAudio
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.volume_up_outlined, size: 20),
                color: AppColors.textSecondary,
                onPressed: _isGeneratingAudio || _audioUrl != null ? null : _generateAudio,
              ),
            ],
          ),
          if (_audioUrl != null) ...[
            const SizedBox(height: 10),
            AudioPlayerWidget(audioUrl: _audioUrl!),
          ],
        ],
      ),
    );
  }
}