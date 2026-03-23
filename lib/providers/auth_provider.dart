import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends Notifier<UserModel?> {
  FirebaseService get _firebaseService => ref.read(firebaseServiceProvider);

  @override
  UserModel? build() {
    return null;
  }

  Future<void> login(String email, String password) async {
    final credential = await _firebaseService.signInWithEmail(email, password);
    if (credential.user?.uid != null) {
      final user = await _firebaseService.getUserProfile(credential.user!.uid);
      state = user;
      return;
    }
    state = UserModel(uid: 'mock_uid', email: email, fullName: 'Demo User');
  }

  Future<void> createAccount(String fullName, String email, String password) async {
    try {
      final credential = await _firebaseService.createUserWithEmail(email, password);
      final uid = credential.user?.uid;

      if (uid == null) {
        throw Exception('Unable to create account. Please try again.');
      }

      final user = UserModel(uid: uid, email: email, fullName: fullName);
      await _firebaseService.saveUserProfile(user);
      state = user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      throw Exception('Account creation failed. ${e.toString()}');
    }
  }
  
  void logout() {
    state = null;
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Account creation failed. Please try again.';
    }
  }

  String _friendlyFirebaseMessage(FirebaseException e) {
    if (e.code == 'no-app') {
      return 'Firebase is not configured yet. Please run FlutterFire setup for this app first.';
    }
    return e.message ?? 'Firebase error. Please try again.';
  }
}
