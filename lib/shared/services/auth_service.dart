import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  FirebaseAuth get _authInstance {
    if (Firebase.apps.isEmpty) {
      throw StateError(
          'Firebase has not been initialized. Call Firebase.initializeApp() first.');
    }
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  // Check if Firebase is available
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Current user stream
  Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      debugPrint(
          'Firebase not available - authStateChanges returning empty stream');
      return Stream.value(null);
    }
    return _authInstance.authStateChanges();
  }

  User? get currentUser {
    if (!isFirebaseAvailable) return null;
    return _authInstance.currentUser;
  }

  // Email & Password Authentication
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - signInWithEmailAndPassword skipped');
      return null;
    }

    try {
      final credential = await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = await _getUserModel(credential.user!);
        _logger.i('User signed in successfully: ${credential.user!.uid}');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign in failed: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  Future<UserModel?> createUserWithEmailAndPassword(
      String email, String password,
      {String? displayName}) async {
    if (!isFirebaseAvailable) {
      _logger
          .w('Firebase not available - createUserWithEmailAndPassword skipped');
      return null;
    }

    try {
      final credential = await _authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name if provided
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Create user document in Firestore
        final userModel = await _createUserDocument(credential.user!);
        _logger.i('User created successfully: ${credential.user!.uid}');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e('User creation failed: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during user creation: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - signInWithGoogle skipped');
      return null;
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('Google sign in cancelled by user');
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _authInstance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userModel = await _createUserDocument(userCredential.user!);
        _logger.i('Google sign in successful: ${userCredential.user!.uid}');
        return userModel;
      }
      return null;
    } catch (e) {
      _logger.e('Google sign in failed: $e');
      rethrow;
    }
  }

  // Apple Sign In (iOS/macOS)
  Future<UserModel?> signInWithApple() async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - signInWithApple skipped');
      return null;
    }

    try {
      final appleProvider = AppleAuthProvider();
      final userCredential =
          await _authInstance.signInWithProvider(appleProvider);

      if (userCredential.user != null) {
        final userModel = await _createUserDocument(userCredential.user!);
        _logger.i('Apple sign in successful: ${userCredential.user!.uid}');
        return userModel;
      }
      return null;
    } catch (e) {
      _logger.e('Apple sign in failed: $e');
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - sendPasswordResetEmail skipped');
      return;
    }

    try {
      await _authInstance.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Password reset failed: ${e.message}');
      rethrow;
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - sendEmailVerification skipped');
      return;
    }

    try {
      final user = _authInstance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _logger.i('Email verification sent to: ${user.email}');
      }
    } catch (e) {
      _logger.e('Email verification failed: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    if (!isFirebaseAvailable) return;

    try {
      await _authInstance.currentUser?.reload();
    } catch (e) {
      _logger.e('User reload failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - signOut skipped');
      return;
    }

    try {
      await _googleSignIn.signOut();
      await _authInstance.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - deleteAccount skipped');
      return;
    }

    try {
      final user = _authInstance.currentUser;
      if (user != null) {
        await user.delete();
        _logger.i('User account deleted: ${user.uid}');
      }
    } catch (e) {
      _logger.e('Account deletion failed: $e');
      rethrow;
    }
  }

  // Helper Methods
  Future<UserModel> _createUserDocument(User firebaseUser) async {
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

    try {
      await _firestoreService.createUser(userModel);
    } catch (e) {
      _logger.w('Failed to create user document in Firestore: $e');
      // Continue even if Firestore fails
    }

    return userModel;
  }

  Future<UserModel?> _getUserModel(User firebaseUser) async {
    try {
      // Try to get user from Firestore first
      final userModel = await _firestoreService.getUser(firebaseUser.uid);
      if (userModel != null) {
        // Update last login time
        final updatedUser = userModel.copyWith(
          lastLoginAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        return updatedUser;
      }

      // If user doesn't exist in Firestore, create it
      return await _createUserDocument(firebaseUser);
    } catch (e) {
      _logger.w('Failed to get user from Firestore: $e');
      // Return basic user model based on Firebase user
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        preferences: {},
      );
    }
  }

  // Utility Methods
  bool get isSignedIn {
    if (!isFirebaseAvailable) return false;
    return _authInstance.currentUser != null;
  }

  String? get currentUserId {
    if (!isFirebaseAvailable) return null;
    return _authInstance.currentUser?.uid;
  }

  String? get currentUserEmail {
    if (!isFirebaseAvailable) return null;
    return _authInstance.currentUser?.email;
  }
}
