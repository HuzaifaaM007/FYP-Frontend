import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/subject_list_provider.dart';
import 'course_list_screen.dart';

class CatalogHomeScreen extends StatefulWidget {
  const CatalogHomeScreen({super.key});

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  late final SubjectListProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SubjectListProvider();
    _provider.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(title: const Text('Courses')),
        body: Consumer<SubjectListProvider>(
          builder: (context, provider, _) {
            if (provider.state == CatalogLoadState.loading) return const LoadingView();
            if (provider.state == CatalogLoadState.error) {
              return ErrorView(message: provider.errorMessage ?? 'Something went wrong.', onRetry: provider.load);
            }
            if (provider.subjects.isEmpty) {
              return const Center(child: Text('No subjects available yet.', style: TextStyle(color: AppColors.textSecondary)));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: provider.subjects.length,
              itemBuilder: (context, index) {
                final subject = provider.subjects[index];
                final accent = AppColors.accentPalette[index % AppColors.accentPalette.length];
                return _SubjectTile(name: subject.name, accentColor: accent, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CourseListScreen(subjectSlug: subject.slug, subjectName: subject.name)),
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String name;
  final Color accentColor;
  final VoidCallback onTap;

  const _SubjectTile({required this.name, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(name, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}