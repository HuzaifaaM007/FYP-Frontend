import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.audioUrl);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load audio.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) return Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final isPlaying = snapshot.data?.playing ?? false;
          return Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36),
                color: AppColors.textPrimary,
                onPressed: () => isPlaying ? _player.pause() : _player.play(),
              ),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final total = _player.duration ?? Duration.zero;
                    return Slider(
                      value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                      max: total.inMilliseconds.toDouble().clamp(1, double.infinity),
                      onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}