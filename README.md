# FocusFlow

An ADHD-friendly Flutter task app: maroon/slate theme, animated task
completion, nested expandable subtasks with a focus mode, and nagging
interval reminders that keep firing until a task (and all its subtasks)
are truly done.

## Features

- **Bottom nav**: Home (dashboard/stats), Calendar, Tasks.
- **Animated completion**: tapping a task's circle fills it from the
  center outward, draws a checkmark stroke, and pops a small confetti
  burst. Unchecking reverses the whole animation.
- **Nested subtasks**: tasks can have subtasks, which can have their own
  subtasks, expandable/collapsible at every level. "Focus Mode" drills
  into a single task and hides everything else.
- **Nagging reminders**: set a task to nag every N minutes; it keeps
  re-firing local notifications (with a "Mark Complete" action button)
  until the task and every nested subtask are checked off.

## Building the APK (no local Flutter install needed)

This repo intentionally does not commit the generated Android platform
folder. Every push triggers `.github/workflows/build-apk.yml`, which:

1. Installs the Flutter SDK on the runner.
2. Runs `flutter create --platforms=android .` to generate the missing
   `android/` scaffolding around the existing `lib/` and `pubspec.yaml`.
3. Runs `flutter pub get` and `flutter build apk --debug`.
4. Uploads the resulting APK as a workflow artifact.

To get an installable APK: push a commit, open the **Actions** tab on
GitHub, open the latest **Build APK** run, and download the
`focusflow-debug-apk` artifact from the run summary.

## Project layout

```
lib/
  main.dart                     entrypoint, notification wiring
  theme/app_theme.dart           maroon/slate ThemeData
  models/task.dart               Task model (recursive subtasks)
  providers/task_provider.dart   Riverpod state + persistence
  services/reminder_service.dart notification scheduling + WorkManager
  widgets/
    animated_task_tile.dart      circle-fill/checkmark/confetti animation
    subtask_tree.dart            recursive expandable subtask list
    task_form_sheet.dart         add task/subtask bottom sheet
    bottom_nav_shell.dart        Home/Calendar/Tasks scaffold
  screens/
    home_screen.dart
    calendar_screen.dart
    tasks_screen.dart
    focus_mode_screen.dart
```

## Notes / known simplifications

- Persistence uses `shared_preferences` with JSON, not Isar/Hive - fewer
  moving parts to get right without a local Flutter SDK to compile
  against, and plenty for a single-user task list.
- Navigation is plain `Navigator`/`MaterialPageRoute` rather than
  `go_router`, for the same reason.
- Reminders are scheduled as a chain of exact local notifications
  (re-topped-up on app resume) rather than relying solely on
  `workmanager`'s 15-minute minimum interval, since the app wants to
  support nags shorter than that. `workmanager` still runs a 15-minute
  background catch-up as a safety net.
