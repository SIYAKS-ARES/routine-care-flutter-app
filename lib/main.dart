import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/firebase_config.dart';
import 'core/di/injection.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/routine_reminder_service.dart';
import 'features/routine_management/data/repositories/routine_repository.dart';
import 'features/routine_management/presentation/pages/routine_home_page.dart'; // Auth wrapper yerine direkt routine page

void main() async {
  // Setup global error handling BEFORE ensureInitialized
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      debugPrint('=== Starting initialization ===');

      // Initialize timezone database (required for flutter_local_notifications)
      debugPrint('Step 1: Initializing timezone...');
      try {
        tz.initializeTimeZones();
        debugPrint('Step 1a: Timezone zones initialized');
        tz.setLocalLocation(
            tz.getLocation('America/New_York')); // Default timezone
        debugPrint('Step 1b: Timezone location set - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 1: Timezone initialization FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continue - timezone will use system default
      }

      // Initialize Firebase
      debugPrint('Step 2: Initializing Firebase...');
      try {
        await FirebaseConfig.initialize();
        debugPrint('Step 2: Firebase initialized - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 2: Firebase initialization FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        // App will continue with local storage only
      }

      // Initialize Hive
      debugPrint('Step 3: Initializing Hive...');
      try {
        await Hive.initFlutter();
        debugPrint('Step 3a: Hive.initFlutter() done');
        await Hive.openBox(AppConstants.hiveBoxName);
        debugPrint('Step 3b: Hive box opened - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 3: Hive initialization FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow; // Hive is critical, cannot continue without it
      }

      // Initialize dependency injection
      debugPrint('Step 4: Configuring dependency injection...');
      try {
        await configureDependencies();
        debugPrint('Step 4: Dependency injection - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 4: Dependency injection FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow; // DI is critical
      }

      // Initialize Notification Services
      debugPrint('Step 5: Initializing notification services...');
      try {
        final notificationService = getIt<NotificationService>();
        debugPrint('Step 5a: Got NotificationService from DI');
        await notificationService.initialize();
        debugPrint('Step 5b: NotificationService initialized');

        final reminderService = getIt<RoutineReminderService>();
        debugPrint('Step 5c: Got RoutineReminderService from DI');
        reminderService.initialize();
        debugPrint('Step 5d: RoutineReminderService initialized - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 5: Notification services FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continue without notification services - app will work but without notifications
      }

      // Initialize RoutineRepository
      debugPrint('Step 6: Initializing RoutineRepository...');
      try {
        final routineRepository = getIt<RoutineRepository>();
        debugPrint('Step 6a: Got RoutineRepository from DI');
        routineRepository.initialize();
        debugPrint('Step 6: RoutineRepository initialized - SUCCESS');
      } catch (e, stackTrace) {
        debugPrint('Step 6: RoutineRepository FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continue - repository will initialize lazily if needed
      }

      debugPrint('Step 7: Starting app...');
      debugPrint('Step 8: Creating MaterialApp...');
      runApp(const ProviderScope(child: MyApp()));
      debugPrint('Step 9: App started - SUCCESS');
    },
    (error, stackTrace) {
      debugPrint('FATAL: Unhandled error in zone: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: Building MaterialApp');
    return MaterialApp(
      title: 'Routine Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SafeHomePage(),
      builder: (context, child) {
        // Add error handling at app level
        ErrorWidget.builder = (FlutterErrorDetails details) {
          debugPrint('Widget Error: ${details.exception}');
          debugPrint('Stack trace: ${details.stack}');
          return Material(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Bir hata oluştu',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uygulama yeniden başlatılıyor...',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}

// Safe wrapper for RoutineHomePage
class SafeHomePage extends StatelessWidget {
  const SafeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('SafeHomePage: Building with ErrorBoundary');
    return ErrorBoundary(
      child: const RoutineHomePage(),
    );
  }
}

// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    debugPrint('ErrorBoundary: Widget initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    if (_error != null) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Bir hata oluştu',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      debugPrint('ErrorBoundary caught error: $error');
      debugPrint('Stack trace: $stackTrace');

      // Schedule error display for next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      });

      // Return temporary loading screen
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
