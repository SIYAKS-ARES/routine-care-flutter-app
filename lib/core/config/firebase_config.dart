import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue without Firebase - app will work with local storage only
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;

  static FirebaseOptions _getFirebaseOptions() {
    // Firebase config for ideaspark-fssoc project
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCRlQLdsYZjfZbaq4U7dnPJlnTpwZy-X3Y",
        authDomain: "ideaspark-fssoc.firebaseapp.com",
        projectId: "ideaspark-fssoc",
        storageBucket: "ideaspark-fssoc.appspot.com",
        messagingSenderId: "855989954837",
        appId: "1:855989954837:web:routine-care-web",
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: "AIzaSyCRlQLdsYZjfZbaq4U7dnPJlnTpwZy-X3Y",
          appId: "1:855989954837:android:routine-care-android",
          messagingSenderId: "855989954837",
          projectId: "ideaspark-fssoc",
          storageBucket: "ideaspark-fssoc.appspot.com",
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: "AIzaSyCRlQLdsYZjfZbaq4U7dnPJlnTpwZy-X3Y",
          appId: "1:855989954837:ios:routine-care-ios",
          messagingSenderId: "855989954837",
          projectId: "ideaspark-fssoc",
          storageBucket: "ideaspark-fssoc.appspot.com",
          iosBundleId: "com.routinecare.app",
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: "AIzaSyCRlQLdsYZjfZbaq4U7dnPJlnTpwZy-X3Y",
          appId: "1:855989954837:macos:routine-care-macos",
          messagingSenderId: "855989954837",
          projectId: "ideaspark-fssoc",
          storageBucket: "ideaspark-fssoc.appspot.com",
          iosBundleId: "com.routinecare.app",
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }
}
