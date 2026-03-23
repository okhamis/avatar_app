import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      print("Error fetching user profile from Firestore: $e");
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
      print("Error saving user to Firestore: $e");
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("FirebaseAuth Login Error: $e");
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("FirebaseAuth Signup Error: $e");
      return null;
    }
  }
}
