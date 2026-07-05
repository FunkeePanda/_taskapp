import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Bottom sheet for creating a new task or subtask, including an
/// optional nagging reminder interval in minutes.
class TaskFormSheet extends StatefulWidget {
  final String title;
  const TaskFormSheet({super.key, this.title = 'New Task'});

  static Future<Task?> show(BuildContext context, {String title = 'New Task'}) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.slateSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(title: title),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  int? _reminderMinutes;

  static const List<int?> _presets = [null, 15, 30, 60, 120];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      Task(
        title: title,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        reminderIntervalMinutes: _reminderMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'What needs doing?'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nag me every',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presets.map((minutes) {
              final selected = _reminderMinutes == minutes;
              return ChoiceChip(
                label: Text(minutes == null ? 'Off' : '${minutes}m'),
                selected: selected,
                selectedColor: AppColors.maroon,
                backgroundColor: AppColors.slateSurfaceAlt,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                onSelected: (_) => setState(() => _reminderMinutes = minutes),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
