import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/course_video.dart';
import '../services/catalog_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  const VideoPlayerScreen({super.key, required this.videoId, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _service = CatalogApiService();
  CourseVideo? _video;
  String? _error;
  bool _loading = true;

  YoutubePlayerController? _youtube;
  VideoPlayerController? _direct;

  // Watch tracking: counts the distinct seconds of the video that were really played (skipping ahead does not count).
  Timer? _timer;
  final Set<int> _watched = {};
  int? _lastPos;
  int? _duration;
  double _percent = 0; // 0..1
  bool _completed = false;
  bool _reporting = false;
  int _reportFailures = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _startTracking(CourseVideo video) {
    _duration = video.durationSeconds;
    _timer?.cancel();
    if (_youtube == null && _direct == null) return; // external (e.g. Vimeo): cannot be tracked
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_completed || !mounted) return;
    int? pos;
    var playing = false;
    var dur = _duration;
    try {
      if (_youtube != null) {
        playing = _youtube!.value.playerState == PlayerState.playing;
        if (playing) {
          pos = (await _youtube!.currentTime).floor();
          if (dur == null || dur <= 0) {
            final d = await _youtube!.duration;
            if (d > 0) dur = d.floor();
          }
        }
      } else if (_direct != null) {
        final v = _direct!.value;
        playing = v.isPlaying;
        pos = v.position.inSeconds;
        if (dur == null || dur <= 0) dur = v.duration.inSeconds;
      }
    } catch (_) {
      return;
    }
    if (!playing || pos == null) {
      _lastPos = null;
      return;
    }
    _watched.add(pos);
    // Continuous playback: fill the second we may have skipped between two samples (jitter, 2x speed).
    if (_lastPos != null && pos - _lastPos! == 2) _watched.add(pos - 1);
    _lastPos = pos;
    _duration = dur;
    if (dur != null && dur > 0) {
      _percent = (_watched.length / dur).clamp(0.0, 1.0);
      if (mounted) setState(() {});
      if (_percent >= 0.9) _report(_percent * 100);
    }
  }

  Future<void> _report(double percent) async {
    if (_reporting || _completed || _reportFailures >= 3) return;
    _reporting = true;
    try {
      final done = await _service.reportProgress(
        kind: 'video',
        entityId: widget.videoId,
        percent: percent,
        seconds: _watched.length,
      );
      if (done && mounted) {
        setState(() => _completed = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video completed')));
      }
    } catch (_) {
      _reportFailures++;
    } finally {
      _reporting = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final video = await _service.fetchVideo(widget.videoId);
      if (video.provider == 'youtube' && video.externalId != null) {
        _youtube = YoutubePlayerController.fromVideoId(
          videoId: video.externalId!,
          autoPlay: false,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
      } else if (video.provider == 'direct') {
        final controller = VideoPlayerController.networkUrl(Uri.parse(video.sourceUrl));
        await controller.initialize();
        _direct = controller;
      }
      _video = video;
      _startTracking(video);
    } catch (_) {
      _error = 'Could not load this video.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _youtube?.close();
    _direct?.dispose();
    super.dispose();
  }

  Future<void> _openExternally(String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _content(_video!),
    );
  }

  Widget _content(CourseVideo video) {
    return ListView(
      children: [
        _player(video),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(video.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (video.durationLabel != null) ...[
                const SizedBox(height: 4),
                Text(video.durationLabel!, style: TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 10),
              _progressRow(video),
              if (video.description != null && video.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectableText(video.description!, style: const TextStyle(height: 1.5)),
              ],
              if (video.attribution != null && video.attribution!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Source: ${video.attribution}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              if (video.transcript != null) _Transcript(text: video.transcript!, format: video.transcriptFormat),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressRow(CourseVideo video) {
    final trackable = _youtube != null || _direct != null;
    if (!trackable) {
      // Vimeo / external links open outside the app, so the app cannot see how much was watched.
      return _completed
          ? Text('Watched ✓', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w600))
          : OutlinedButton.icon(
              onPressed: () => _report(100),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as watched'),
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _completed ? 1 : _percent,
            minHeight: 5,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation(_completed ? AppColors.accentGreen : AppColors.accentOrange),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _completed ? 'Watched ✓' : 'Watched ${(_percent * 100).round()}%  (counts as done at 90%)',
          style: TextStyle(color: _completed ? AppColors.accentGreen : AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _player(CourseVideo video) {
    if (_youtube != null) {
      return YoutubePlayer(controller: _youtube!, aspectRatio: 16 / 9);
    }
    final direct = _direct;
    if (direct != null) {
      return Column(
        children: [
          AspectRatio(aspectRatio: direct.value.aspectRatio, child: VideoPlayer(direct)),
          VideoProgressIndicator(direct, allowScrubbing: true),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: direct,
            builder: (_, value, __) => IconButton(
              iconSize: 36,
              icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: () => value.isPlaying ? direct.pause() : direct.play(),
            ),
          ),
        ],
      );
    }
    // Vimeo (and anything else) opens in the browser or the Vimeo app.
    return Container(
      height: 200,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: () => _openExternally(video.sourceUrl),
        icon: const Icon(Icons.open_in_new),
        label: Text('Watch on ${video.provider == 'vimeo' ? 'Vimeo' : 'the web'}'),
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  final String text;
  final String? format;
  const _Transcript({required this.text, required this.format});

  /// Reads WebVTT into (time, line) pairs. Plain text transcripts come back as one entry per paragraph.
  List<MapEntry<String?, String>> _entries() {
    if (format != 'vtt') {
      return text
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => MapEntry<String?, String>(null, p))
          .toList();
    }
    final entries = <MapEntry<String?, String>>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains('-->')) continue;
      final start = lines[i].split('-->').first.trim();
      final parts = start.split(':');
      final shown = parts.length == 3 && parts.first == '00' ? '${parts[1]}:${parts[2].split('.').first}' : start.split('.').first;
      final cue = <String>[];
      var j = i + 1;
      while (j < lines.length && lines[j].trim().isNotEmpty) {
        cue.add(lines[j].trim());
        j++;
      }
      if (cue.isNotEmpty) entries.add(MapEntry(shown, cue.join(' ')));
      i = j;
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Transcript', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.key != null)
                    SizedBox(width: 48, child: Text(entry.key!, style: TextStyle(color: AppColors.accentBlue, fontSize: 12))),
                  Expanded(child: SelectableText(entry.value, style: const TextStyle(height: 1.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
