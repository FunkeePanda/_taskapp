import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/subtask_tree.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<Task> _tasksForDay(List<Task> tasks, DateTime day) {
    return tasks
        .where((t) => t.dueDate != null && _isSameDay(t.dueDate!, day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final selected = _selectedDay ?? DateTime.now();
    final dayTasks = _tasksForDay(tasks, selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDay(selected, day),
            eventLoader: (day) => _tasksForDay(tasks, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.slateSurfaceAlt,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.maroon,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.maroonLight,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: TextStyle(color: AppColors.textPrimary),
              outsideTextStyle: TextStyle(color: AppColors.textSecondary),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(color: AppColors.textPrimary, fontSize: 16),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: AppColors.textPrimary),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: AppColors.textPrimary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary),
              weekendStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayTasks.isEmpty
                ? const Center(
                    child: Text(
                      'Nothing due this day.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        dayTasks.map((t) => SubtaskTree(task: t)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
