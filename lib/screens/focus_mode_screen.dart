import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/subtask_tree.dart';

/// An immersive, single-task view: just this task and its subtree, with
/// everything else (bottom nav, other tasks) out of sight so the user
/// can drill into one thing at a time.
class FocusModeScreen extends ConsumerWidget {
  final String taskId;

  const FocusModeScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskListProvider);
    final notifier = ref.read(taskListProvider.notifier);
    final freshTask = notifier.findTask(taskId);

    if (freshTask == null) {
      return const Scaffold(
        body: Center(child: Text('Task no longer exists')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        backgroundColor: AppColors.slateBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              freshTask.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (freshTask.notes != null && freshTask.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  freshTask.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (freshTask.hasSubtasks)
              ...freshTask.subtasks.map(
                (sub) => SubtaskTree(task: sub, depth: 0),
              )
            else
              const Text(
                'No subtasks yet - this is a single, focused task.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
