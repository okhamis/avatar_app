import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/avatar_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  FirebaseAuth get _auth {
    _ensureFirebaseInitialized();
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    _ensureFirebaseInitialized();
    return FirebaseFirestore.instance;
  }

  void _ensureFirebaseInitialized() {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'no-app',
        message: 'Firebase is not configured. Add Firebase config files and initialize Firebase before auth.',
      );
    }
  }

  Future<UserModel> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(uid, doc.data()!);
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'User profile not found.',
      );
    } catch (e) {
      debugPrint("Error fetching user profile from Firestore: $e");
      rethrow;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    try {
      final data = user.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'schemaVersion': 2,
        });
      await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user to Firestore: $e");
      rethrow;
    }
  }

  Future<void> updateUserTrainingFlags({
    required String uid,
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      };
      if (hasFaceTrained != null) updates['hasFaceTrained'] = hasFaceTrained;
      if (hasVoiceCloned != null) updates['hasVoiceCloned'] = hasVoiceCloned;
      if (hasBehaviorTrained != null) updates['hasBehaviorTrained'] = hasBehaviorTrained;
      if (isLive != null) updates['isLive'] = isLive;
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating user training flags: $e");
      rethrow;
    }
  }

  Future<AvatarModel?> getAvatarProfile(String ownerId) async {
    try {
      final doc = await _firestore.collection('avatars').doc(ownerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AvatarModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint("Error fetching avatar profile: $e");
      rethrow;
    }
  }

  Future<void> saveAvatarProfile(AvatarModel avatar) async {
    try {
      final data = avatar.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': avatar.createdAt.toIso8601String(),
        });
      await _firestore.collection('avatars').doc(avatar.ownerId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving avatar profile: $e");
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("FirebaseAuth Login Error: $e");
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuth Signup Error [${e.code}]: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("FirebaseAuth Signup Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("FirebaseAuth Logout Error: $e");
      rethrow;
    }
  }
}
