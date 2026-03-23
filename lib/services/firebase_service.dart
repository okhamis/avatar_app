import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
        final data = doc.data()!;
        return UserModel(
          uid: uid,
          email: data['email'] ?? '',
          fullName: data['fullName'] ?? 'Unknown User',
        );
      }
    } catch (e) {
      debugPrint("Error fetching user profile from Firestore: $e");
    }
    return UserModel(uid: uid, email: "error@example.com", fullName: "Fallback User");
  }

  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'fullName': user.fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user to Firestore: $e");
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
    } catch (e) {
      debugPrint("FirebaseAuth Signup Error: $e");
      rethrow;
    }
  }
}
