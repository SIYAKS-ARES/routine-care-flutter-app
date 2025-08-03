import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../core/di/injection.dart';

// Auth Service Provider
final authServiceProvider =
    Provider<AuthService>((ref) => getIt<AuthService>());

// Firebase User Stream Provider
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Model Provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firebaseUser = authService.currentUser;

  if (firebaseUser == null) return null;

  // Create user model from Firebase user
  return UserModel(
    uid: firebaseUser.uid,
    email: firebaseUser.email!,
    displayName: firebaseUser.displayName,
    photoURL: firebaseUser.photoURL,
    createdAt: DateTime.now(), // Would be fetched from Firestore in real app
    lastLoginAt: DateTime.now(),
    isEmailVerified: firebaseUser.emailVerified,
    preferences: {},
  );
});

// Auth State Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Authentication State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Logger _logger = Logger();

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _setAuthenticatedUser(user);
      } else {
        _setUnauthenticated();
      }
    });
  }

  void _setAuthenticatedUser(User firebaseUser) {
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
      preferences: {},
    );

    state = state.copyWith(
      user: userModel,
      isAuthenticated: true,
      isLoading: false,
      error: null,
    );
  }

  void _setUnauthenticated() {
    state = state.copyWith(
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    );
  }

  // Sign In with Email and Password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userModel =
          await _authService.signInWithEmailAndPassword(email, password);
      if (userModel != null) {
        state = state.copyWith(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
        _logger.i('User signed in successfully: ${userModel.uid}');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Sign in failed: $e');
    }
  }

  // Create User with Email and Password
  Future<void> createUserWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userModel = await _authService.createUserWithEmailAndPassword(
          email, password,
          displayName: displayName);
      if (userModel != null) {
        state = state.copyWith(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
        _logger.i('User created successfully: ${userModel.uid}');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('User creation failed: $e');
    }
  }

  // Sign In with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userModel = await _authService.signInWithGoogle();
      if (userModel != null) {
        state = state.copyWith(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
        _logger.i('Google sign in successful: ${userModel.uid}');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Google sign in failed: $e');
    }
  }

  // Sign In with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userModel = await _authService.signInWithApple();
      if (userModel != null) {
        state = state.copyWith(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
        _logger.i('Apple sign in successful: ${userModel.uid}');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Apple sign in failed: $e');
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      _logger.i('Password reset email sent to: $email');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Password reset failed: $e');
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      _logger.i('Email verification sent');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      _logger.e('Email verification failed: $e');
    }
  }

  // Reload User
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _logger.i('User reloaded');
    } catch (e) {
      _logger.e('User reload failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = const AuthState();
      _logger.i('User signed out successfully');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Sign out failed: $e');
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.deleteAccount();
      state = const AuthState();
      _logger.i('Account deleted successfully');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _logger.e('Account deletion failed: $e');
    }
  }

  // Clear Error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
