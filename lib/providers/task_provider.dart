import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/reminder_service.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier();
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kTasksStorageKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    await ReminderService.instance.resyncAll(state);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((t) => t.toJson()).toList());
    await prefs.setString(kTasksStorageKey, encoded);
  }

  void addTask(Task task) {
    state = [...state, task];
    _persist();
    if (task.reminderIntervalMinutes != null) {
      ReminderService.instance.scheduleNagging(task);
    }
  }

  void addSubtask(String parentId, Task subtask) {
    state = _mapTree(state, (t) {
      if (t.id == parentId) {
        return t.copyWith(subtasks: [...t.subtasks, subtask]);
      }
      return t;
    });
    _persist();
    if (subtask.reminderIntervalMinutes != null) {
      ReminderService.instance.scheduleNagging(subtask);
    }
  }

  void toggleComplete(String taskId) {
    state = _mapTree(state, (t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        completed: !t.completed,
        completedAt: !t.completed ? DateTime.now() : null,
      );
    });
    _persist();

    final updated = _find(state, taskId);
    if (updated == null) return;
    if (updated.isTrulyComplete) {
      ReminderService.instance.cancelForTask(updated.id);
    } else if (updated.reminderIntervalMinutes != null) {
      ReminderService.instance.scheduleNagging(updated);
    }
  }

  void updateTask(Task updatedTask) {
    state = _mapTree(state, (t) => t.id == updatedTask.id ? updatedTask : t);
    _persist();
    if (updatedTask.reminderIntervalMinutes != null &&
        !updatedTask.isTrulyComplete) {
      ReminderService.instance.scheduleNagging(updatedTask);
    } else {
      ReminderService.instance.cancelForTask(updatedTask.id);
    }
  }

  void deleteTask(String taskId) {
    ReminderService.instance.cancelForTask(taskId);
    state = _removeFromTree(state, taskId);
    _persist();
  }

  Task? findTask(String taskId) => _find(state, taskId);

  /// Applies a completion that was actioned from a background
  /// notification button while the app wasn't in the foreground.
  void applyBackgroundCompletion(String taskId) {
    final task = _find(state, taskId);
    if (task != null && !task.completed) {
      toggleComplete(taskId);
    }
  }

  Task? _find(List<Task> tasks, String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
      final found = _find(t.subtasks, id);
      if (found != null) return found;
    }
    return null;
  }

  List<Task> _mapTree(List<Task> tasks, Task Function(Task) transform) {
    return tasks.map((t) {
      final mapped = transform(t);
      return mapped.copyWith(subtasks: _mapTree(mapped.subtasks, transform));
    }).toList();
  }

  List<Task> _removeFromTree(List<Task> tasks, String id) {
    return tasks
        .where((t) => t.id != id)
        .map((t) => t.copyWith(subtasks: _removeFromTree(t.subtasks, id)))
        .toList();
  }
}
