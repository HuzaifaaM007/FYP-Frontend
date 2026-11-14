import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/lecture_card.dart';
import '../providers/lecture_list_provider.dart';
import 'lecture_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LectureListScreen extends StatefulWidget {
  const LectureListScreen({super.key});

  @override
  State<LectureListScreen> createState() => _LectureListScreenState();
}

class _LectureListScreenState extends State<LectureListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureListProvider>().loadLectures();
    });
  }

  Future<void> _pickAndUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'pptx', 'docx'],
    );
    if (files.isEmpty) return;

    final file = files.single;
    final path = kIsWeb ? null : file.path;
    // Chrome has no file path, so read the bytes instead (file_picker 12+ API).
    final bytes = path == null ? await file.readAsBytes() : null;
    if (path == null && bytes == null) return;
    if (!mounted) return;

    final provider = context.read<LectureListProvider>();
    final lecture = await provider.uploadLecture(
      path,
      file.name,
      bytes: bytes,
    );

    if (!mounted) return;
    if (lecture != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LectureDetailScreen(lectureId: lecture.lectureId),
        ),
      );
    } else if (provider.uploadError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.uploadError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LectureListProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Lectures')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => context.read<LectureListProvider>().loadLectures(),
            child: _buildBody(provider),
          ),
          if (provider.isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing lecture with AI...\nThis can take a moment.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isUploading ? null : _pickAndUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }

  Widget _buildBody(LectureListProvider provider) {
    if (provider.state == LectureListState.loading) {
      return const LoadingView();
    }
    if (provider.state == LectureListState.error) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          ErrorView(
            message: provider.errorMessage ?? 'Something went wrong.',
            onRetry: () => context.read<LectureListProvider>().loadLectures(),
          ),
        ],
      );
    }
    if (provider.lectures.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(
            child: Text(
              'No lectures yet.\nTap Upload to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // clears the FAB
      itemCount: provider.lectures.length,
      itemBuilder: (context, index) {
        final lecture = provider.lectures[index];
        return GestureDetector(
          onLongPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Delete lecture?'),
                content: Text(
                  '"${lecture.title}" and its topics, quizzes and audio will be removed.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(d, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              final deleted = await context
                  .read<LectureListProvider>()
                  .deleteLecture(lecture.lectureId);
              if (!deleted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not delete the lecture.')),
                );
              }
            }
          },
          child: LectureCard(
            lecture: lecture,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LectureDetailScreen(lectureId: lecture.lectureId),
              ),
            ),
          ),
        );
      },
    );
  }
}