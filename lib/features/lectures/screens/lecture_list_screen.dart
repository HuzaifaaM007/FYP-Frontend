import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/lecture_card.dart';
import '../providers/lecture_list_provider.dart';
import 'lecture_detail_screen.dart';

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
    if (files.isEmpty || files.single.path == null) return;

    final file = files.single;
    if (!mounted) return;

    final provider = context.read<LectureListProvider>();
    final lecture = await provider.uploadLecture(file.path!, file.name);

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
        return LectureCard(
          lecture: lecture,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LectureDetailScreen(lectureId: lecture.lectureId),
            ),
          ),
        );
      },
    );
  }
}
