import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/focus_mode_screen.dart';
import '../theme/app_theme.dart';
import 'animated_task_tile.dart';
import 'task_form_sheet.dart';

/// Recursively renders a task and every level of its nested subtasks.
/// Each node can be expanded/collapsed independently and drilled into
/// via "Focus" for an immersive, distraction-free view of just that
/// branch of the tree.
class SubtaskTree extends ConsumerStatefulWidget {
  final Task task;
  final int depth;

  const SubtaskTree({super.key, required this.task, this.depth = 0});

  @override
  ConsumerState<SubtaskTree> createState() => _SubtaskTreeState();
}

class _SubtaskTreeState extends ConsumerState<SubtaskTree> {
  bool _expanded = true;

  void _openFocusMode(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusModeScreen(taskId: task.id),
      ),
    );
  }

  Future<void> _addSubtask(
      BuildContext context, WidgetRef ref, Task task) async {
    final subtask = await TaskFormSheet.show(context, title: 'New Subtask');
    if (subtask != null) {
      ref.read(taskListProvider.notifier).addSubtask(task.id, subtask);
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(taskListProvider.notifier);
    final task = widget.task;

    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedTaskTile(
                  task: task,
                  expanded: _expanded,
                  onToggle: () => notifier.toggleComplete(task.id),
                  onExpandToggle: task.hasSubtasks
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  onFocus: () => _openFocusMode(context, task),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: AppColors.textSecondary),
                tooltip: 'Add subtask',
                onPressed: () => _addSubtask(context, ref, task),
              ),
            ],
          ),
          if (task.hasSubtasks && _expanded)
            ...task.subtasks.map(
              (sub) => SubtaskTree(task: sub, depth: widget.depth + 1),
            ),
        ],
      ),
    );
  }
}
