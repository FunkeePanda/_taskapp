import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/task_provider.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_shell.dart';

late final ProviderContainer _container;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _container = ProviderContainer();

  await ReminderService.instance.init(
    onCompleteAction: (taskId) {
      _container
          .read(taskListProvider.notifier)
          .applyBackgroundCompletion(taskId);
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const FocusFlowApp(),
    ),
  );
}

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final tasks = _container.read(taskListProvider);
      ReminderService.instance.resyncAll(tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const BottomNavShell(),
    );
  }
}
