import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/firebase_config.dart';
import 'core/di/injection.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/routine_reminder_service.dart';
import 'features/routine_management/presentation/pages/routine_home_page.dart'; // Auth wrapper yerine direkt routine page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // App will continue with local storage only
  }

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxName);

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Notification Services
  try {
    final notificationService = getIt<NotificationService>();
    await notificationService.initialize();

    final reminderService = getIt<RoutineReminderService>();
    reminderService.initialize();

    debugPrint('Notification services initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize notification services: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home:
          const RoutineHomePage(), // Geçici olarak direkt routine page açıyoruz
    );
  }
}
