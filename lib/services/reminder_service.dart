import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../models/task.dart';

const String kOverdueCheckTaskName = 'focusflow.overdue_check';
const String kTasksStorageKey = 'focusflow_tasks';

/// Notification action ids wired up in [ReminderService.init].
const String kCompleteAction = 'complete_action';
const String kSnoozeAction = 'snooze_action';

/// How many future occurrences to schedule at once for a nagging task.
/// Scheduling is re-topped-up whenever the app resumes, so this only
/// needs to cover a reasonable stretch of time between opens.
const int _occurrencesPerSchedule = 40;

/// Handles every notification concern: permissions, scheduling a chain of
/// nagging reminders per task at its configured interval, cancelling them
/// once a task (and all its subtasks) are truly complete, and a
/// best-effort WorkManager background catch-up in case the OS kills the
/// exact-alarm chain.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init({
    void Function(String taskId)? onCompleteAction,
    void Function(String taskId)? onNotificationTap,
  }) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId == null) return;
        if (response.actionId == kCompleteAction) {
          onCompleteAction?.call(taskId);
        } else if (response.actionId == kSnoozeAction) {
          // Snoozing simply lets the next already-scheduled nag fire;
          // nothing to do beyond dismissing this one.
        } else {
          onNotificationTap?.call(taskId);
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      kOverdueCheckTaskName,
      kOverdueCheckTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    _initialized = true;
  }

  /// Deterministic, stable notification id range for a task so we can
  /// cancel every scheduled occurrence for it later.
  int _baseIdFor(String taskId) => taskId.hashCode & 0x0FFFFFFF;

  Future<void> scheduleNagging(Task task) async {
    await cancelForTask(task.id);
    final interval = task.reminderIntervalMinutes;
    if (interval == null || interval <= 0 || task.isTrulyComplete) return;

    const androidDetails = AndroidNotificationDetails(
      'focusflow_nag_channel',
      'Task Reminders',
      channelDescription: 'Nagging reminders for incomplete FocusFlow tasks',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(kCompleteAction, 'Mark Complete'),
        AndroidNotificationAction(kSnoozeAction, 'Snooze'),
      ],
    );
    const details = NotificationDetails(android: androidDetails);

    final baseId = _baseIdFor(task.id);
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < _occurrencesPerSchedule; i++) {
      final fireTime = now.add(Duration(minutes: interval * (i + 1)));
      await _plugin.zonedSchedule(
        baseId + i,
        'Still waiting: ${task.title}',
        "This one's not done yet - tap Complete or open FocusFlow.",
        fireTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    }
  }

  Future<void> cancelForTask(String taskId) async {
    final baseId = _baseIdFor(taskId);
    for (int i = 0; i < _occurrencesPerSchedule; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Re-syncs every incomplete, nag-enabled task's schedule. Call this on
  /// app resume so chains don't run dry between opens.
  Future<void> resyncAll(List<Task> roots) async {
    for (final task in _flatten(roots)) {
      if (task.reminderIntervalMinutes != null && !task.isTrulyComplete) {
        await scheduleNagging(task);
      } else {
        await cancelForTask(task.id);
      }
    }
  }

  Iterable<Task> _flatten(List<Task> roots) sync* {
    for (final task in roots) {
      yield task;
      yield* _flatten(task.subtasks);
    }
  }
}

/// Top-level WorkManager entry point. Runs in a separate background
/// isolate, so it only has SharedPreferences (no Riverpod container) to
/// work with - it reads the last-saved task snapshot and fires a single
/// grouped nudge for whatever is still overdue as a safety net alongside
/// the exact-alarm chain scheduled by [ReminderService.scheduleNagging].
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kOverdueCheckTaskName) return true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kTasksStorageKey);
    if (raw == null) return true;

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final roots =
        decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();

    int overdueCount = 0;
    void walk(List<Task> tasks) {
      for (final t in tasks) {
        if (t.reminderIntervalMinutes != null && !t.isTrulyComplete) {
          overdueCount++;
        }
        walk(t.subtasks);
      }
    }

    walk(roots);
    if (overdueCount == 0) return true;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    const androidDetails = AndroidNotificationDetails(
      'focusflow_overdue_channel',
      'Overdue Summary',
      channelDescription: 'Background catch-up nudge for overdue tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    await plugin.show(
      999999,
      'FocusFlow',
      overdueCount == 1
          ? 'You still have 1 task waiting on you.'
          : 'You still have $overdueCount tasks waiting on you.',
      const NotificationDetails(android: androidDetails),
    );

    return true;
  });
}
