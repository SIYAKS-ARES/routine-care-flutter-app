class AppConstants {
  // App Info
  static const String appName = 'Routine Care';
  static const String appVersion = '2.0.0';

  // Storage Keys
  static const String hiveBoxName = 'routineAppDataBase';
  static const String currentRoutineListKey = 'currentRoutineList';
  static const String settingsBoxName = 'settingsBox';
  static const String userPreferencesKey = 'userPreferences';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String routinesCollection = 'routines';
  static const String statisticsCollection = 'statistics';
  static const String categoriesCollection = 'categories';
  static const String achievementsCollection = 'achievements';

  // Theme
  static const String themeKey = 'theme_mode';
  static const String isDarkModeKey = 'is_dark_mode';

  // Date Formats
  static const String dateFormat = 'yyyyMMdd';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';

  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;

  // Validation
  static const int minRoutineNameLength = 2;
  static const int maxRoutineNameLength = 50;
  static const int maxRoutinesPerUser = 50;

  // Analytics
  static const int defaultHeatMapDays = 365; // 1 year
  static const int maxStatisticsDays = 730; // 2 years

  // Sync Settings
  static const Duration syncTimeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(seconds: 5);
  static const int maxRetryAttempts = 3;

  // Notification
  static const String notificationChannelId = 'routine_reminders';
  static const String notificationChannelName = 'Routine Reminders';
  static const String notificationChannelDescription =
      'Daily routine reminder notifications';
}
