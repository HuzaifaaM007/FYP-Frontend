import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/planner_item.dart';
import '../providers/planner_provider.dart';

const _types = ['goal', 'session', 'reminder'];

/// The server sends UTC times. If an offset is missing, treat the value as UTC, then show it in local time.
DateTime? _parseServerTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
  return DateTime.tryParse(hasZone ? raw : '${raw}Z')?.toLocal();
}

DateTime? _itemTime(PlannerItem item) => _parseServerTime(item.dueAt) ?? _parseServerTime(item.scheduledFor);

String _formatWhen(BuildContext context, DateTime time) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(time)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Listening (not just onTap) so the + button also follows tab swipes.
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PlannerProvider>().load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    final type = _types[_tabController.index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _AddItemSheet(itemType: type),
    );
  }

  Future<void> _toggle(PlannerItem item) async {
    try {
      await context.read<PlannerProvider>().toggleComplete(item);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update that item. Check your connection.')),
      );
    }
  }

  Future<void> _confirmDelete(PlannerItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this item?'),
        content: Text(item.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<PlannerProvider>().remove(item);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete that item.')));
    }
  }

  List<PlannerItem> _sorted(List<PlannerItem> list) {
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final timeA = _itemTime(a);
      final timeB = _itemTime(b);
      if (timeA != null && timeB != null) return timeA.compareTo(timeB);
      if (timeA != null) return -1;
      if (timeB != null) return 1;
      return 0;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Goals'), Tab(text: 'Sessions'), Tab(text: 'Reminders')],
        ),
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(PlannerProvider provider) {
    if (provider.state == PlannerLoadState.loading) return const LoadingView();
    if (provider.state == PlannerLoadState.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: () => provider.load(),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: _types.map((type) => _buildList(provider, type)).toList(),
    );
  }

  Widget _buildList(PlannerProvider provider, String type) {
    final items = _sorted(provider.items.where((item) => item.itemType == type).toList());
    final emptyText = type == 'goal'
        ? 'No goals yet. Tap + to add one.'
        : type == 'session'
            ? 'No study sessions planned. Tap + to schedule one.'
            : 'No reminders yet. Tap + to set one.';

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (type == 'reminder')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'At the chosen time your phone shows a notification, and it also appears under the bell on Home. Long-press an item to delete it.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Text(emptyText, style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...items.map((item) => _itemTile(context, item)),
        ],
      ),
    );
  }

  Widget _itemTile(BuildContext context, PlannerItem item) {
    final when = _itemTime(item);
    final overdue = !item.isCompleted && when != null && when.isBefore(DateTime.now());
    final details = <Widget>[
      if (item.description != null && item.description!.isNotEmpty) Text(item.description!),
      if (when != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                overdue ? Icons.warning_amber_rounded : Icons.schedule,
                size: 14,
                color: overdue ? AppColors.accentPink : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  overdue ? 'Overdue · ${_formatWhen(context, when)}' : _formatWhen(context, when),
                  style: TextStyle(fontSize: 12, color: overdue ? AppColors.accentPink : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onLongPress: () => _confirmDelete(item),
        child: CheckboxListTile(
        value: item.isCompleted,
        onChanged: (_) => _toggle(item),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        subtitle: details.isEmpty
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: details),
        controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final String itemType;

  const _AddItemSheet({required this.itemType});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _when;
  bool _saving = false;
  String? _error;

  bool get _timeRequired => widget.itemType == 'reminder';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _when ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _error = null;
    });
  }

  void _setIn(Duration duration) => setState(() {
        _when = DateTime.now().add(duration);
        _error = null;
      });

  void _setTomorrowMorning() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _when = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      _error = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }
    if (_timeRequired && _when == null) {
      setState(() => _error = 'Pick when you want to be reminded.');
      return;
    }
    if (_timeRequired && !_when!.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a time in the future.');
      return;
    }

    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    final isoTime = _when?.toUtc().toIso8601String();
    final provider = context.read<PlannerProvider>();

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.itemType == 'goal') {
        await provider.addGoal(title, description, isoTime);
      } else if (widget.itemType == 'session') {
        await provider.addSession(title, description, isoTime);
      } else {
        await provider.addReminder(title, description, isoTime);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.itemType[0].toUpperCase() + widget.itemType.substring(1);
    final whenText = _when == null
        ? (_timeRequired ? 'Pick date & time' : 'Pick date & time (optional)')
        : _formatWhen(context, _when!);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New $label', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDateTime,
              icon: const Icon(Icons.event),
              label: Text(whenText),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('In 2 min'), onPressed: () => _setIn(const Duration(minutes: 2))),
                ActionChip(label: const Text('In 1 hour'), onPressed: () => _setIn(const Duration(hours: 1))),
                ActionChip(label: const Text('Tomorrow 9:00'), onPressed: _setTomorrowMorning),
                if (_when != null && !_timeRequired)
                  ActionChip(label: const Text('Clear date'), onPressed: () => setState(() => _when = null)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            AppButton(label: 'Add', isLoading: _saving, onPressed: _saving ? null : _save),
          ],
        ),
      ),
    );
  }
}
