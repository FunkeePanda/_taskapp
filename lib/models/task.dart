import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A task or subtask node. Tasks can nest arbitrarily deep via [subtasks].
class Task {
  final String id;
  String title;
  String? notes;
  bool completed;
  final DateTime createdAt;
  DateTime? completedAt;
  DateTime? dueDate;

  /// If set, the app nags with a local notification every N minutes
  /// while this task remains incomplete.
  int? reminderIntervalMinutes;

  List<Task> subtasks;

  Task({
    String? id,
    required this.title,
    this.notes,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
    this.reminderIntervalMinutes,
    List<Task>? subtasks,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        subtasks = subtasks ?? <Task>[];

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get totalSubtaskCount =>
      subtasks.fold(0, (sum, s) => sum + 1 + s.totalSubtaskCount);

  int get completedSubtaskCount => subtasks.fold(
      0, (sum, s) => sum + (s.completed ? 1 : 0) + s.completedSubtaskCount);

  /// A task only counts as *truly* done once it and every nested
  /// subtask are checked off - this is what silences reminders.
  bool get isTrulyComplete =>
      completed && subtasks.every((s) => s.isTrulyComplete);

  Task copyWith({
    String? title,
    String? notes,
    bool? completed,
    DateTime? completedAt,
    DateTime? dueDate,
    int? reminderIntervalMinutes,
    bool clearReminder = false,
    List<Task>? subtasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      reminderIntervalMinutes: clearReminder
          ? null
          : (reminderIntervalMinutes ?? this.reminderIntervalMinutes),
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'reminderIntervalMinutes': reminderIntervalMinutes,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String?,
        completed: json['completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        reminderIntervalMinutes: json['reminderIntervalMinutes'] as int?,
        subtasks: (json['subtasks'] as List<dynamic>? ?? [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
