import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/planner_provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PlannerProvider>().load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSheet(String itemType) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New ${itemType[0].toUpperCase()}${itemType.substring(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)'), maxLines: 2),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final provider = context.read<PlannerProvider>();
                final title = titleController.text.trim();
                final desc = descController.text.trim().isEmpty ? null : descController.text.trim();

                switch (itemType) {
                  case 'goal':
                    await provider.addGoal(title, desc, null);
                    break;
                  case 'session':
                    await provider.addSession(title, desc, null);
                    break;
                  case 'reminder':
                    await provider.addReminder(title, desc, null);
                    break;
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final currentType = ['goal', 'session', 'reminder'][_tabController.index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: 'Goals'), Tab(text: 'Sessions'), Tab(text: 'Reminders')],
        ),
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(currentType),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(PlannerProvider provider) {
    if (provider.state == PlannerLoadState.loading) return const LoadingView();
    if (provider.state == PlannerLoadState.error) {
      return ErrorView(message: provider.errorMessage ?? 'Something went wrong.', onRetry: () => provider.load());
    }

    return TabBarView(
      controller: _tabController,
      children: ['goal', 'session', 'reminder'].map((type) {
        final filtered = provider.items.where((item) => item.itemType == type).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('Nothing here yet.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                value: item.isCompleted,
                onChanged: (_) => context.read<PlannerProvider>().toggleComplete(item),
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                subtitle: item.description != null ? Text(item.description!) : null,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}