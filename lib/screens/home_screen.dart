import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/subtask_tree.dart';
import '../widgets/task_form_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final total = tasks.length;
    final done = tasks.where((t) => t.isTrulyComplete).length;
    final nagging = tasks
        .where((t) => t.reminderIntervalMinutes != null && !t.isTrulyComplete)
        .length;
    final upNext = tasks.where((t) => !t.isTrulyComplete).take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('FocusFlow')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final task = await TaskFormSheet.show(context, title: 'New Task');
          if (task != null) {
            ref.read(taskListProvider.notifier).addTask(task);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Done',
                  value: '$done/$total',
                  color: AppColors.maroon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Nagging me',
                  value: '$nagging',
                  color: AppColors.maroonLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Up next',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (upNext.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nothing pending - nice work.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...upNext.map((t) => SubtaskTree(task: t)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slateSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
