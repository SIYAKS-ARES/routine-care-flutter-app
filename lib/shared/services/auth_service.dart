import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Email & Password Authentication
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
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
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('Google sign in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

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
    try {
      final appleProvider = AppleAuthProvider();
      final userCredential = await _auth.signInWithProvider(appleProvider);

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
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Password reset failed: ${e.message}');
      rethrow;
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
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
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _logger.e('User reload failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
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
  bool get isSignedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
}
