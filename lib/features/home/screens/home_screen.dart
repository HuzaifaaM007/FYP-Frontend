import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/recommendation_tile.dart';
import '../providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Sensei'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeProvider>().loadAll(),
        child: _buildBody(home),
      ),
    );
  }

  Widget _buildBody(HomeProvider home) {
    if (home.state == HomeLoadState.loading) {
      return const LoadingView();
    }
    if (home.state == HomeLoadState.error) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          ErrorView(
            message: home.errorMessage ?? 'Something went wrong.',
            onRetry: () => context.read<HomeProvider>().loadAll(),
          ),
        ],
      );
    }

    final stats = home.stats!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Avg. Quiz Score',
                value: '${stats.averageScore.toStringAsFixed(0)}%',
                accentColor: AppColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Quizzes Taken',
                value: '${stats.totalQuizzesTaken}',
                accentColor: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Lectures Uploaded',
                value: '${stats.totalUploads}',
                accentColor: AppColors.accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Audio Plays',
                value: '${stats.topicAudioPlays}',
                accentColor: AppColors.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (home.weakTopics.isNotEmpty) ...[
          const Text('Topics to Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...home.weakTopics.take(3).map(
            (topic) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${topic.attempts} attempt${topic.attempts == 1 ? '' : 's'}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${topic.averageScore.toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Recommended for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (home.recommendations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recommendations yet — take a few quizzes to get personalized picks.',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...home.recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final accent = AppColors.accentPalette[index % AppColors.accentPalette.length];
            return RecommendationTile(
              title: item.explanation,
              reason: item.reasonCode.replaceAll('_', ' '),
              accentColor: accent,
              onTap: () {
                context.read<HomeProvider>().dismissRecommendation(item.recommendationId); // placeholder nav target below
              },
              onDismiss: () => context.read<HomeProvider>().dismissRecommendation(item.recommendationId),
            );
          }),
      ],
    );
  }
}