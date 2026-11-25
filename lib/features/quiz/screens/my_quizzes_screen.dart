import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/my_quiz.dart';
import '../services/my_quizzes_service.dart';
import 'quiz_results_screen.dart';
import 'quiz_taking_screen.dart';

/// Lists every quiz the student has generated, newest first.
/// Submitted quizzes open their results (answers + BRAIN); unfinished ones can be continued.
class MyQuizzesScreen extends StatefulWidget {
  const MyQuizzesScreen({super.key});

  @override
  State<MyQuizzesScreen> createState() => _MyQuizzesScreenState();
}

enum _Filter { all, submitted, unfinished }

class _MyQuizzesScreenState extends State<MyQuizzesScreen> {
  final _api = MyQuizzesService();
  List<MyQuizItem>? _items;
  String? _error;
  bool _loading = true;
  bool _opening = false;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _reason(e);
      });
    }
  }

  String _reason(Object e) {
    if (e is DioException) {
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      if (detail is String) return detail;
      if (e.response == null) return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Could not load your quizzes. Please try again.';
  }

  Future<void> _open(MyQuizItem item) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final detail = await _api.detail(item.quizId);
      if (!mounted) return;
      if (detail.submission != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultsScreen(submission: detail.submission!, quiz: detail.quiz, fromHistory: true),
          ),
        );
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizTakingScreen(quiz: detail.quiz)));
        _load(); // the student may have submitted it just now
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_reason(e))));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  List<MyQuizItem> get _visible {
    final items = _items ?? [];
    switch (_filter) {
      case _Filter.submitted:
        return items.where((i) => i.submitted).toList();
      case _Filter.unfinished:
        return items.where((i) => !i.submitted).toList();
      case _Filter.all:
        return items;
    }
  }

  Color _scoreColor(double p) {
    if (p >= 80) return AppColors.success;
    if (p >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Quizzes')),
      body: Stack(
        children: [
          _body(),
          if (_opening)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items == null) return const LoadingView();
    if (_error != null && _items == null) return ErrorView(message: _error!, onRetry: _load);

    final all = _items ?? [];
    final done = all.where((i) => i.submitted).toList();
    final avg = done.isEmpty ? null : done.map((i) => i.percentage ?? 0).reduce((a, b) => a + b) / done.length;
    final visible = _visible;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _summaryBox('Quizzes', '${all.length}', AppColors.accentBlue),
              const SizedBox(width: 10),
              _summaryBox('Submitted', '${done.length}', AppColors.accentPurple),
              const SizedBox(width: 10),
              _summaryBox('Average', avg == null ? '–' : '${avg.round()}%', avg == null ? AppColors.textSecondary : _scoreColor(avg)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              _chip('All', _Filter.all),
              _chip('Submitted', _Filter.submitted),
              _chip('Not finished', _Filter.unfinished),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.quiz_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    all.isEmpty
                        ? 'No quizzes yet.\nOpen a lesson and tap "Generate Quiz" to make your first one.'
                        : 'Nothing here for this filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...visible.map(_tile),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final selected = _filter == f;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = f),
      selectedColor: AppColors.primary.withOpacity(0.18),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 13),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      showCheckmark: false,
    );
  }

  Widget _tile(MyQuizItem item) {
    final p = item.percentage;
    final badgeColor = item.submitted && p != null ? _scoreColor(p) : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(item),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.submitted && p != null
                      ? Text('${p.round()}%', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 15))
                      : Icon(Icons.hourglass_empty, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                      if (item.courseTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(item.courseTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        item.submitted
                            ? '${item.totalScore ?? 0} / ${item.totalPoints} points · ${item.totalQuestions} questions'
                            : 'Not finished · ${item.totalQuestions} questions',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(_date(item.submittedAt ?? item.createdAt),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
