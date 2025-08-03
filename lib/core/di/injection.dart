import 'package:get_it/get_it.dart';

import '../../features/routine_management/data/repositories/routine_repository.dart';
import '../../features/category_management/data/repositories/category_repository.dart';
import '../../features/goal_management/data/repositories/goal_repository.dart';
import '../../features/achievement_system/data/repositories/achievement_repository.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/routine_reminder_service.dart';
import '../../shared/services/firestore_service.dart';
import '../../shared/services/auth_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Firebase Services
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Notification Services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<RoutineReminderService>(
      () => RoutineReminderService());

  // Repositories
  getIt.registerLazySingleton<RoutineRepository>(() => RoutineRepository());
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepository());
  getIt.registerLazySingleton<GoalRepository>(() => GoalRepository());
  getIt.registerLazySingleton<AchievementRepository>(
      () => AchievementRepository());

  // You can add more dependencies here as we build more features
}
