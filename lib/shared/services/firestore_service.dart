import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../models/routine_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final Logger _logger = Logger();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // User operations
  Future<void> createUser(UserModel user) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - createUser skipped');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      _logger.i('User created successfully: ${user.uid}');
    } catch (e) {
      _logger.e('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - getUser skipped');
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - updateUser skipped');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
      _logger.i('User updated successfully: ${user.uid}');
    } catch (e) {
      _logger.e('Error updating user: $e');
      rethrow;
    }
  }

  // Routine operations
  Future<void> createRoutine(RoutineModel routine, String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - createRoutine skipped');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id)
          .set(routine.toJson());
      _logger.i('Routine created successfully: ${routine.id}');
    } catch (e) {
      _logger.e('Error creating routine: $e');
      rethrow;
    }
  }

  Future<List<RoutineModel>> getUserRoutines(String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - getUserRoutines skipped');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .get();

      return querySnapshot.docs
          .map((doc) => RoutineModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error getting user routines: $e');
      return [];
    }
  }

  Future<void> updateRoutine(RoutineModel routine, String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - updateRoutine skipped');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id)
          .update(routine.toJson());
      _logger.i('Routine updated successfully: ${routine.id}');
    } catch (e) {
      _logger.e('Error updating routine: $e');
      rethrow;
    }
  }

  Future<void> deleteRoutine(String routineId, String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - deleteRoutine skipped');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .delete();
      _logger.i('Routine deleted successfully: $routineId');
    } catch (e) {
      _logger.e('Error deleting routine: $e');
      rethrow;
    }
  }

  Stream<List<RoutineModel>> getUserRoutinesStream(String userId) {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - getUserRoutinesStream skipped');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RoutineModel.fromJson(doc.data()))
              .toList());
    } catch (e) {
      _logger.e('Error getting user routines stream: $e');
      return Stream.value([]);
    }
  }

  Future<void> saveRoutineCompletion(
      String routineId, String userId, DateTime completionDate) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - saveRoutineCompletion skipped');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .add({
        'routineId': routineId,
        'completionDate': Timestamp.fromDate(completionDate),
        'createdAt': Timestamp.now(),
      });
      _logger.i('Routine completion saved: $routineId');
    } catch (e) {
      _logger.e('Error saving routine completion: $e');
      rethrow;
    }
  }

  // Statistics operations
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - getUserStatistics skipped');
      return {};
    }

    try {
      final completionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .get();

      // Calculate basic statistics
      final totalCompletions = completionsSnapshot.docs.length;
      final routineIds = completionsSnapshot.docs
          .map((doc) => doc.data()['routineId'] as String)
          .toSet();

      return {
        'totalCompletions': totalCompletions,
        'uniqueRoutines': routineIds.length,
        'lastUpdated': Timestamp.now(),
      };
    } catch (e) {
      _logger.e('Error getting user statistics: $e');
      return {};
    }
  }

  // Generic document helpers
  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - addDocument skipped for $collection');
      return;
    }

    try {
      await _firestore.collection(collection).add(data);
      _logger.i('Document added to $collection');
    } catch (e) {
      _logger.e('Error adding document to $collection: $e');
      rethrow;
    }
  }

  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    if (!isFirebaseAvailable) {
      _logger.w(
          'Firebase not available - setDocument skipped for $collection/$docId');
      return;
    }

    try {
      await _firestore.collection(collection).doc(docId).set(data);
      _logger.i('Document set: $collection/$docId');
    } catch (e) {
      _logger.e('Error setting document $collection/$docId: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    if (!isFirebaseAvailable) {
      _logger.w(
          'Firebase not available - updateDocument skipped for $collection/$docId');
      return;
    }

    try {
      await _firestore.collection(collection).doc(docId).update(data);
      _logger.i('Document updated: $collection/$docId');
    } catch (e) {
      _logger.e('Error updating document $collection/$docId: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    if (!isFirebaseAvailable) {
      _logger.w(
          'Firebase not available - deleteDocument skipped for $collection/$docId');
      return;
    }

    try {
      await _firestore.collection(collection).doc(docId).delete();
      _logger.i('Document deleted: $collection/$docId');
    } catch (e) {
      _logger.e('Error deleting document $collection/$docId: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDocument(
      String collection, String docId) async {
    if (!isFirebaseAvailable) {
      _logger.w(
          'Firebase not available - getDocument skipped for $collection/$docId');
      return null;
    }

    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.data();
    } catch (e) {
      _logger.e('Error getting document $collection/$docId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionWithQuery(
    String collection,
    String field,
    dynamic value,
  ) async {
    if (!isFirebaseAvailable) {
      _logger.w(
          'Firebase not available - getCollectionWithQuery skipped for $collection');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error querying $collection by $field: $e');
      return [];
    }
  }

  // Batch operations for efficiency
  Future<void> batchCreateRoutines(
      List<RoutineModel> routines, String userId) async {
    if (!isFirebaseAvailable) {
      _logger.w('Firebase not available - batchCreateRoutines skipped');
      return;
    }

    try {
      final batch = _firestore.batch();
      for (final routine in routines) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routine.id);
        batch.set(docRef, routine.toJson());
      }
      await batch.commit();
      _logger.i('Batch created ${routines.length} routines');
    } catch (e) {
      _logger.e('Error batch creating routines: $e');
      rethrow;
    }
  }
}
